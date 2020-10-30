# frozen_string_literal: true

module Utils
  module LoadTesting
    # Builds a JMeter test plan for submitting a lot of ODK form submissions.
    #
    # This test building process should be run on the server that is being targeted
    # for the test because it will query the database while building the sample submission
    # data (i.e. the XML for the ODK submission) for the test.
    #
    # The actual JMeter test will be run on a different server that does not have NEMO installed.
    # It will just know how to make a bunch of HTTP requests based on the options and data we give it.
    class ODKSubmissionLoadTest < LoadTest
      # Required `options`:
      #   username: User doing the submitting
      #   password: User's password
      #   form_id: The ID of the form being submitted to.
      #
      # The test currently knows how to handle the following question types:
      #   text, long_text, barcode, integer, counter, decimal, location, select_one,
      #   select_multiple, datetime, date, time

      CSV_FILENAME = "submissions.csv"

      # Generates a bunch of test data to be used to make the test requests and stores it in a CSV file.
      def generate_test_data
        CSV.open(path.join(CSV_FILENAME), "wb") do |csv|
          csv << ["submission_filename"]

          submissions_path = path.join("submissions")
          FileUtils.mkdir_p(submissions_path)

          100.times do |i|
            data = odk_submission(form)
            submission_filename = "submissions/#{i + 1}.xml"
            write_file(submission_filename, data)
            csv << [submission_filename]
          end
        end
      end

      # The endpoint we're POSTing to expects the following:
      # - Basic authentication
      # - A form/multipart content type
      # - A file with param name `xml_submission_file` containing the submission.
      def plan
        username = options[:username]
        password = options[:password]
        mission_name = form.mission.compact_name
        files = [{path: "${submission_filename}", paramname: "xml_submission_file", mimetype: "text/xml"}]

        test do
          csv_data_set_config(filename: CSV_FILENAME, variableNames: "submission_filename")

          transaction("post_odk_response") do
            basic_auth(username, password)
            submit("/en/m/#{mission_name}/submission", files: files)
          end
        end
      end

      private

      def form
        Form.find(options[:form_id])
      end

      def test_value(question)
        case question.qtype_name
        when "text"
          Faker::Lorem.sentence
        when "long_text"
          Faker::Lorem.paragraph
        when "integer", "counter"
          Faker::Number.number(digits: 3)
        when "decimal"
          Faker::Number.decimal(l_digits: 3)
        when "datetime"
          n = Faker::Number.number(digits: 3)
          n.days.ago.to_s
        when "date"
          n = Faker::Number.number(digits: 3)
          n.days.ago.to_date.to_s
        when "time"
          n = Faker::Number.number(digits: 3)
          n.days.ago.to_s.split(" ")[1]
        when "select_one", "select_multiple"
          "on#{question.options.rand.option_nodes.first.id}"
        when "barcode"
          Faker::Code.ean
        when "location"
          lat = Faker::Address.latitude
          lng = Faker::Address.longitude
          "#{lat} #{lng}"
        end
      end

      def odk_submission(form)
        data = form_items.map do |item|
          value = test_value(item.question)
          "<#{item.odk_code}>#{value}</#{item.odk_code}>"
        end.join("\n")

        "<?xml version='1.0' ?><data id='#{form.id}' version='#{form_code}'>\n#{data}\n</data>"
      end

      def form_items
        @form_items ||= form.preordered_items.map { |i| ODK::DecoratorFactory.decorate(i) }
      end

      def form_code
        @form_code ||= form.code
      end
    end
  end
end
