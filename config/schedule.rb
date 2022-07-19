# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
# Docs: https://github.com/javan/whenever
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set(:output, {error: "log/cron-error.log", standard: "log/cron.log"})

env(:PATH, ENV["PATH"])
env(:GEM_HOME, ENV["GEM_HOME"])

# Every 6 hours, at half past
every "30 */6 * * *" do
  runner "CleanupJob.perform_later"
end

every 1.minute do
  runner "CacheODataJob.perform_later"
end

every 1.minute do
  runner "DedupeJob.perform_later"
end
