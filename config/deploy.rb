# this deploy file makes use of the multistage facility of capistrano
# there are two stages:
# master - https://cceom.org; master branch; the main ELMO
# demo - https://secure1.cceom.org; demo branch; the staging environment and demo sandbox
# to deploy, e.g.:
#   cap demo deploy

require 'bundler/capistrano'

set :stages, %w(production production-old staging staging-old demo nigeria api cejp-rdc burundi loadtest1)
set :default_stage, "staging"
require "capistrano/ext/multistage"

require 'thinking_sphinx/capistrano'

# this handles installing the whenever tasks
set :whenever_command, "bundle exec whenever"
set(:whenever_identifier) {"elmo_#{stage}"}
require "whenever/capistrano"

# delayed_jobs settings
# NOTE: :delayed_job_server_role must match :thinking_sphinx_roles, which defaults to :db
set :delayed_job_server_role, :db
set :delayed_job_command, 'bundle exec bin/delayed_job'
require 'delayed/recipes'

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

# Always rebuild the search indices to make sure they're fresh and working.
# This also restarts the sphinx daemon.
after "deploy", "thinking_sphinx:rebuild"

after "deploy", "deploy:check_timezones"

after "deploy", "deploy:cleanup" # keep only the last 5 releases

# Tie delayed_job lifecycle to the main lifecycle
after "deploy:stop",    "delayed_job:stop"
after "deploy:start",   "delayed_job:start"
after "deploy:restart", "delayed_job:restart"

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
    # Directories
    run "mkdir -p #{shared_path}/tmp"
    run "mkdir -p #{shared_path}/log"
    run "mkdir -p #{shared_path}/uploads"
    run "mkdir -p #{shared_path}/db/sphinx/#{rails_env}"
    run "mkdir -p #{release_path}/db/sphinx"
    run "ln -nfs #{shared_path}/tmp #{release_path}/tmp"
    run "ln -nfs #{shared_path}/uploads #{release_path}/uploads"
    run "ln -nfs #{shared_path}/log #{release_path}/log"
    run "ln -nfs #{shared_path}/db/sphinx/#{rails_env} #{release_path}/db/sphinx/#{rails_env}"

    # Files
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/memcached_server #{release_path}/config/memcached_server"
    run "ln -nfs #{shared_path}/config/thinking_sphinx.yml #{release_path}/config/thinking_sphinx.yml"
    run "ln -nfs #{shared_path}/config/local_config.rb #{release_path}/config/initializers/local_config.rb"
    run "ln -nfs #{shared_path}/config/railsenv #{release_path}/config/railsenv"
    run "ln -nfs #{shared_path}/app/assets/stylesheets/all/variables/_theme.scss #{release_path}/app/assets/stylesheets/all/variables/_theme.scss"
    run "ln -nfs #{shared_path}/app/assets/images/logo-override.png #{release_path}/app/assets/images/logo-override.png"
  end
  before "deploy:finalize_update", "deploy:symlink_config"

  desc "Copy theme override files to server"
  task :theme_config, role: :app do
    theme = fetch(:theme, "app/assets/stylesheets/all/variables/_default_theme.scss")
    logo = fetch(:logo, "app/assets/images/logo.png")
    run "mkdir -p #{shared_path}/app/assets/stylesheets/all/variables/"
    run "mkdir -p #{shared_path}/app/assets/images/"
    top.upload theme, "#{shared_path}/app/assets/stylesheets/all/variables/_theme.scss"
    top.upload logo, "#{shared_path}/app/assets/images/logo-override.png"
  end

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse #{branch}` == `git rev-parse origin/#{branch}`
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

  desc "Check MySQL timezones."
  task :check_timezones, roles: :web do
    # Runs rake task if 'ok' flag file is not present
    run "cd #{current_path} && [ ! -f tmp/tzok.txt ] && RAILS_ENV=#{rails_env} bundle exec rake db:timezone_test && touch tmp/tzok.txt || echo"
  end

  desc "ping the server so that it connects to db"
  task :ping, roles: :web do
    run "curl -s #{ping_url} > /dev/null"
  end
  after "deploy:restart", "deploy:ping"
end
