# frozen_string_literal: true

namespace :load_test do
  desc "Generate load test plan for ODK submission"
  task odk: :environment do
    generate_test(Utils::LoadTesting::ODKSubmissionLoadTest,
      username: ENV["USERNAME"],
      password: ENV["PASSWORD"],
      form_id: ENV["FORM_ID"])
  end

  desc "Generate load test plan for SMS submission"
  task sms: :environment do
    generate_test(Utils::LoadTesting::SmsSubmissionLoadTest,
      user_id: ENV["USER_ID"],
      form_id: ENV["FORM_ID"],
      test_rows: ENV["TEST_ROWS"].to_i)
  end

  private

  def generate_test(klass, params = {})
    params[:thread_count] ||= ENV["THREADS"]
    params[:duration] ||= ENV["DURATION"]

    test = klass.new(params)
    test.generate_plan
  end
end
