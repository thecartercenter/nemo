# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, "log/cron.log"
env :PATH, ENV["PATH"]
env :GEM_HOME, ENV["GEM_HOME"]

every :reboot do
  rake "ts:start"
end

# Every hour, on the hour
every 1.hour do
  # make sure the daemon is running
  rake "ts:start"
end

# Every hour, at 5 after
every "5 * * * *" do
  # redo the indexes
  rake "ts:index"
end

# Every 6 hours, at half past
every "30 */6 * * *" do
  runner "CleanupJob.perform_later"
end
