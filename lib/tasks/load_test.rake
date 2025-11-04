# frozen_string_literal: true

namespace :load_test do
  desc "Generate load test plan for ODK submission"
  task odk: :environment do
    generate_test(Utils::LoadTesting::ODKSubmissionLoadTest,
      username: ENV.fetch("USERNAME", nil),
      password: ENV.fetch("PASSWORD", nil),
      form_id: ENV.fetch("FORM_ID", nil))
  end

  desc "Generate load test plan for SMS submission"
  task sms: :environment do
    generate_test(Utils::LoadTesting::SmsSubmissionLoadTest,
      user_id: ENV.fetch("USER_ID", nil),
      form_id: ENV.fetch("FORM_ID", nil),
      test_rows: ENV["TEST_ROWS"].to_i)
  end

  private

  def generate_test(klass, params = {})
    params[:thread_count] ||= ENV.fetch("THREADS", nil)
    params[:duration] ||= ENV.fetch("DURATION", nil)

    test = klass.new(params)
    test.generate_plan
  end
end
