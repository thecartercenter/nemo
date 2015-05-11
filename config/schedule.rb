set :output, "log/cron.log"
env :PATH, ENV['PATH']
env :GEM_HOME, ENV['GEM_HOME']

every 1.hour do
  # redo the indexes
  rake "ts:index"

  # make sure the daemon is running
  rake "ts:start"
end
