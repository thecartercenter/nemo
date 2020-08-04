# frozen_string_literal: true

Delayed::Worker.logger = Logger.new(Rails.root.join("log/dj.log"))

Delayed::Worker.queue_attributes = {
  default: {priority: 0},
  odata: {priority: 10}
}
