# frozen_string_literal: true

Delayed::Worker.logger = Logger.new(Rails.root.join("log/dj.log"))
Delayed::Worker.logger.extend(ActiveSupport::Logger.broadcast(Logger.new(STDOUT))) if Rails.env.development?

Delayed::Worker.queue_attributes = {
  default: {priority: 0},
  odata: {priority: 10}
}
