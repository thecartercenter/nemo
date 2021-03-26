# frozen_string_literal: true

Sentry.init do |config|
  # If the Sentry DSN remains nil, Sentry will be disabled.
  next if Rails.env.test? || Cnfg.offline_mode?

  config.dsn = Cnfg.sentry_dsn
  config.breadcrumbs_logger = [:active_support_logger]
  config.release = "nemo@#{Cnfg.system_version}"
end
