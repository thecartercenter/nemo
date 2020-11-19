# frozen_string_literal: true

module Utils
  module LoadTesting
    # Builds a JMeter test plan for submitting a lot of SMS form submissions.
    #
    # This test building process should be run on the server that is being targeted
    # for the test because it will query the database while building the sample submission
    # data (i.e. the message body for the SMS submission) for the test.
    #
    # The actual JMeter test will be run on a different server that does not have NEMO installed.
    # It will just know how to make a bunch of HTTP requests based on the options and data we give it.
    class SmsSubmissionLoadTest < LoadTest
      # Required `options`:
      #   user_id: User doing the submitting
      #   form_id: The ID of the form being submitted to.
      #
      # Optional `options`:
      #   test_rows: the number of test data rows to generate (default 100)
      #
      # The test currently knows how to handle the following question types:
      #   text, long_text, integer, counter, decimal, select_one,
      #   select_multiple, datetime, date, time
      #
      # The submitting user must have a phone number and SMS auth code

      CSV_FILENAME = "submissions.csv"

      # Generates a bunch of test data to be used to make the test requests and stores it in a CSV file.
      def generate_test_data
        test_rows = options[:test_rows] || 100

        CSV.open(path.join(CSV_FILENAME), "wb") do |csv|
          csv << ["message_body"]

          test_rows.times do |i|
            puts "Generating batch #{(i / 1000).to_i + 1} of #{(test_rows / 1000).ceil}" if (i % 1000).zero?
            csv << [sms_submission]
          end
        end
      end

      # The endpoint we're POSTing to expects the following params:
      # - `From`: phone number of the submitting user
      # - `To`: Twilio receiving phone number
      # - `Body`: SMS message body
      def plan
        mission_name = form.mission.compact_name
        url_token = form.mission.setting.incoming_sms_token
        params = submit_params

        test do
          csv_data_set_config(filename: CSV_FILENAME, variableNames: "message_body")

          transaction("post_sms_response") do
            submit("/m/#{mission_name}/sms/submit/#{url_token}", always_encode: true, fill_in: params)
          end
        end
      end

      private

      def submit_params
        {
          "from" => user.phone,
          "body" => "${message_body}",
          "sent_at" => Time.current.strftime("%s"),
          "frontlinecloud" => "1"
        }
      end

      def form
        @form ||= Form.find(options[:form_id])
      end

      def user
        @user ||= User.find(options[:user_id])
      end

      def test_value(question)
        case question.qtype_name
        when "text", "long_text"
          Faker::Lorem.sentence
        when "integer", "counter"
          Faker::Number.number(digits: 3)
        when "decimal"
          Faker::Number.decimal(l_digits: 3)
        when "datetime"
          n = Faker::Number.number(digits: 3)
          n.days.ago.strftime("%Y%m%d %H%M")
        when "date"
          n = Faker::Number.number(digits: 3)
          n.days.ago.strftime("%Y%m%d")
        when "time"
          n = Faker::Number.number(digits: 3)
          n.days.ago.strftime("%H%M")
        when "select_one", "select_multiple"
          n = question.options.length
          options = ("a".."z").to_a[0...n]
          options.rand
        else
          raise ArgumentError, "unsupported question type: #{question.qtype_name}"
        end
      end

      def sms_submission
        values = form_items.each_with_index.map do |item, i|
          value = test_value(item.question)
          "#{i + 1}.#{value}"
        end.join(" ")

        "#{user.sms_auth_code} #{form_code} #{values}"
      end

      def form_items
        @form_items ||= form.preordered_items.select(&:smsable?)
      end

      def form_code
        @form_code ||= form.code
      end
    end
  end
end
