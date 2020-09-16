# frozen_string_literal: true

Raven.configure do |config|
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.release = "nemo@#{configatron.system_version}"
  config.current_environment = Rails.env.to_s
end
