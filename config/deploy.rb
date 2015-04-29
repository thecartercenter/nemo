# this deploy file makes use of the multistage facility of capistrano
# there are two stages:
# master - https://cceom.org; master branch; the main ELMO
# demo - https://secure1.cceom.org; demo branch; the staging environment and demo sandbox
# to deploy, e.g.:
#   cap demo deploy

require 'bundler/capistrano'

set :stages, %w(master staging staging-old demo nigeria api cejp-drc)
set :default_stage, "staging"
require "capistrano/ext/multistage"

require 'thinking_sphinx/capistrano'

# this handles installing the whenever tasks
set :whenever_command, "bundle exec whenever"
set(:whenever_identifier) {"elmo_#{stage}"}
require "whenever/capistrano"

set :application, "elmo"
set :repository, "https://github.com/thecartercenter/elmo.git"
set :deploy_via, :remote_cache

default_run_options[:pty] = true

# rails env is production for all stages
set :rails_env, 'production'

desc "Echo environment vars"
namespace :env do
  task :echo do
    run "echo printing out cap info on remote server"
    run "echo $PATH"
    run "printenv"
  end
end

#after 'deploy:update_code', 'deploy:migrate'

after "deploy", "deploy:cleanup" # keep only the last 5 releases

namespace :deploy do

  task :setup_config, roles: :app do
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.yml.example"), "#{shared_path}/config/database.yml"
    put File.read("config/thinking_sphinx.yml.example"), "#{shared_path}/config/thinking_sphinx.yml"
    put File.read("config/railsenv.example"), "#{shared_path}/config/railsenv"
    put File.read("config/initializers/local_config.rb.example"), "#{shared_path}/config/local_config.rb"
    puts "Now edit the config files in #{shared_path}."
  end
  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/thinking_sphinx.yml #{release_path}/config/thinking_sphinx.yml"
    run "ln -nfs #{shared_path}/config/local_config.rb #{release_path}/config/initializers/local_config.rb"
    run "ln -nfs #{shared_path}/config/railsenv #{release_path}/config/railsenv"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/#{branch}`
      puts "WARNING: HEAD is not the same as origin"
      puts "Run `git push` to sync changes."
      exit
    end
  end
  before "deploy", "deploy:check_revision"

  desc "Create an admin user with temporary password."
  task :create_admin, roles: :web do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} rake db:create_admin"
  end

  desc "ping the server so that it connects to db"
  task :ping, roles: :web do
    run "curl -s #{ping_url} > /dev/null"
  end
  after "deploy:restart", "deploy:ping"

  # This task runs a series of one-time tasks defined in the TASKS array and stores, on the server, a record
  # of which tasks have been run. The idea is similar to database migrations, but for server admin tasks.
  desc "Run one-time tasks"
  task :one_timers, roles: :web do
    VERSION_FILE = "#{shared_path}/one_timers_version"

    # Note that this code runs on the deploying host, not the server. Use `run` to execute stuff on server.
    # These should really be in separate files but was taking too long to figure out how to do it.
    TASKS = [
      # Task 1: Sample task that just prints something.
      Proc.new do
        run "echo '**** FIRST ONE-TIME TASK RAN! ****'"
      end

      # Task 2: Added secret to local_config.
      Proc.new do
        run "sed -i.bak \"s/secret-token/`rake secret`/g\" ./config/#{shared_path}/local_config.rb"
      end
    ]

    cur_version = nil

    run "if [ -e #{VERSION_FILE} ]; then cat #{VERSION_FILE}; else echo '0'; fi" do |ch, str, output|
      cur_version = output.to_i
    end

    TASKS[cur_version...tasks.size].each_with_index do |t,i|
      t.call
      run "echo '#{cur_version + i + 1}' > #{VERSION_FILE}"
    end
  end
  after "deploy:symlink", "deploy:one_timers"
end