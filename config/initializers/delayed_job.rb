# frozen_string_literal: true

Delayed::Worker.logger = Logger.new(Rails.root.join("log", "dj.log"))
