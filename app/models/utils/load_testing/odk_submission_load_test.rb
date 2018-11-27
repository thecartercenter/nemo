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
    # It wil just know how to make a bunch of HTTP requests based on the options and data we give it.
    class OdkSubmissionLoadTest < LoadTest
      # Required `options`:
      #   username: User doing the submitting
      #   password: User's password
      #   form_id: The ID of the form being submitted to.
      #   mission_name: The name of the mission in which the form is being submitted
      #
      # The test currently knows how to handle the following question types:
      #   text, long_text, barcode, integer, counter, decimal, location, select_one,
      #   select_multiple, datetime, date, time

      SUBMISSION_FILENAME = "submission.xml"

      # Generates a bunch of test data to be used to make the test requests and store it in a CSV file.
      def generate_test_data
        form = Form.find(options[:form_id])
        data = odk_submission(form)
        write_file(SUBMISSION_FILENAME, data)
      end

      # The endpoint we're POSTing to expects the following:
      # - Basic authentication
      # - A form/multipart content type
      # - A file with param name `xml_submission_file` containing the submission.
      def plan
        username = options[:username]
        password = options[:password]
        mission_name = options[:mission_name]

        test do
          transaction("post_odk_response") do
            basic_auth(username, password)

            submit("/en/m/#{mission_name}/submission",
              {
                files: [{path: SUBMISSION_FILENAME, paramname: "xml_submission_file", mimetype: "text/xml"}]
              })
          end
        end
      end

      private

      def test_value(question)
        case question.qtype_name
        when "text"
          Faker::Lorem.sentence
        when "long_text"
          Faker::Lorem.paragraph
        when "integer", "counter"
          Faker::Number.number(3)
        when "decimal"
          Faker::Number.decimal(3)
        when "datetime"
          n = Faker::Number.number(3).to_i
          n.days.ago.to_s
        when "date"
          n = Faker::Number.number(3).to_i
          n.days.ago.to_date.to_s
        when "time"
          n = Faker::Number.number(3).to_i
          n.days.ago.to_s.split(" ")[1]
        when "select_one"
          question.options.rand.id
        when "select_multiple"
          # FIXME
        when "barcode"
          Faker::Code.ean
        when "location"
          lat = Faker::Address.latitude
          lng = Faker::Address.longitude
          "#{lat} #{lng}"
        end
      end

      def odk_submission(form, values: [])
        items = form.preordered_items.map { |i| Odk::DecoratorFactory.decorate(i) }

        data = items.map do |item|
          value = test_value(item.question)
          "<#{item.odk_code}>#{value}</#{item.odk_code}>"
        end.join("\n")

        "<?xml version='1.0' ?><data id='#{form.id}' version='#{form.code}'>\n#{data}\n</data>"
      end
    end
  end
end
