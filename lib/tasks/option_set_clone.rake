require "./lib/task_helpers/option_set_clone"

task option_set_clone: :environment do
  Rails.logger = Logger.new(STDOUT)
  OptionSetClone.new.run
end
