# frozen_string_literal: true

namespace :load_test do
  desc "Generate load test plan for ODK submission"
  task odk: :environment do
    generate_test(Utils::LoadTesting::OdkSubmissionLoadTest,
      {
        username: ENV['USERNAME'],
        password: ENV['PASSWORD'],
        mission_name: ENV['MISSION_NAME'],
        form_id: ENV['FORM_ID']
      })
  end

  private

  def generate_test(klass, params = {})
    params[:thread_count] ||= ENV['THREADS']
    params[:duration] = ENV['DURATION']

    test = klass.new(params)
    test.generate
  end
end
