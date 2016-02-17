# Remember to run rake stress:create_msgs_signatures first (with the correct params)
# to have the file with the sms messages.
namespace :stress do
  SERVER_URL = "ec2-user@loadtest2.getelmo.org"
  SERVER_RAKE_TASKS_PATH = "elmo/stress_test/rake_tasks/"

  desc "Deploys tasks to loadtest2 server"
  task :deploy_tasks do
    tasks_path = "./lib/tasks/"
    tasks_to_upload = []
    tasks_to_upload << "#{tasks_path}stress_navigate_app.rake"
    tasks_to_upload << "#{tasks_path}stress_sms_messages.rake"

    msgs_signatures_path = "messages_signature.csv"

    system "scp #{tasks_to_upload.join(' ')} #{SERVER_URL}:#{SERVER_RAKE_TASKS_PATH}/tasks"
    system "scp #{msgs_signatures_path} #{SERVER_URL}:#{SERVER_RAKE_TASKS_PATH}"
  end
end
