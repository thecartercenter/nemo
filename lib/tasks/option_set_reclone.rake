# frozen_string_literal: true

require "./lib/task_helpers/option_set_reclone"

task option_set_reclone: :environment do
  Rails.logger = Logger.new(STDOUT)
  OptionSetReclone.new.run
end
