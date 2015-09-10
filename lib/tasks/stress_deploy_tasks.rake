# Remember to run rake stress:create_msgs_signatures first (with the correct params)
# to have the file with the sms messages.
namespace :stress do
  desc "Deploys tasks to loadtest2 server"
  task :deploy_tasks do
    task_path = "./lib/tasks/stress_test.rake"
    msgs_signatures_path = "messages_signature.csv"
    server_url = "ec2-user@loadtest2.getelmo.org"
    server_rake_tasks_path = "elmo/stress_test/rake_tasks/"

    system "scp #{task_path} #{server_url}:#{server_rake_tasks_path}/tasks"
    system "scp #{msgs_signatures_path} #{server_url}:#{server_rake_tasks_path}"
  end
end
