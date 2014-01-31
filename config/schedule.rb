# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, "log/cron.log"
set :environment, ENV['RAILS_ENV']

# define a job type to run the per-server railsenv script
job_type :rake_with_env, "cd :path && source config/railsenv && RAILS_ENV=:environment bundle exec rake :task --silent :output"

every 1.hour do
  # redo the indexes
  rake_with_env "ts:index"

  # make sure the daemon is running
  rake_with_env "ts:start"
end