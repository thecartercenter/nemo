# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, "log/cron.log"
env :PATH, ENV['PATH']
env :GEM_HOME, ENV['GEM_HOME']

every 1.hour do
  # redo the indexes
  rake_with_env "ts:index"

  # make sure the daemon is running
  rake_with_env "ts:start"
end