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
      attr_accessor :options

      # `options` is a hash containing info necessary to construct the test requests. Specifically:
      # username: User doing the submitting
      # password: User's password
      # form_id: The ID of the form being submitted to.
      # thread_count: The number of threads to execute.
      # duration: How long each thread should run.
      #
      # The test currently knows how to handle the following question types:
      #   text, long_text, barcode, integer, counter, decimal, location, select_one,
      #   select_multiple, datetime, date, time
      def initialize(options)
        self.options = options
      end

      # Generates a bunch of test data to be used to make the test requests and store it in a CSV file.
      def generate_test_data

      end

      # The endpoint we're POSTing to expects the following:
      # - Basic authentication
      # - A form/multipart content type
      # - A file with param name `xml_submission_file` containing the submission.
      def plan
        test do
          defaults(domain: domain, port: port.to_i, protocol: "https")
          cookies(clear_each_iteration: true)

          # LEFT OFF HERE. NEED TO FIRST WRITE THE CSV FILE WITH APPROPRIATE INPUT DATA TO TEST.
          # THIS WILL DEPEND ON INCOMING OPTIONS LIKE QING IDS AND ETC.
          # THEN READ IT IN TEST SIMILAR TO THE BELOW. COLUMNS WILL PROBABLY BE LIKE XML BODY, ETC.

          csv_data_set_config filename: "submissions.csv",
                              variableNames: "xml"

          threads count: count.to_i, loops: loops.to_i, scheduler: false do
            think_time 100, 50

            transaction "Send SMS messages" do
              header(name: "X-Twilio-Stub-Signature", value: "${twilio_signature}")

              submit name: "sms-submit", url: "/m/#{mission_name}/sms/submit/#{sms_incoming_token}",
                     always_encode: true,
                     fill_in: {"From" => "${phone_number}", "Body" => "${message}"}
            end
          end
        end
      end
    end
  end
end
