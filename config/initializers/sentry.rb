# frozen_string_literal: true

Sentry.init do |config|
  # If the Sentry DSN remains nil, Sentry will be disabled.
  next if Rails.env.test? || Cnfg.offline_mode?

  config.dsn = "https://a81af08ff85042f3ae314e6c685853a3@o448595.ingest.sentry.io/5430181"
  config.breadcrumbs_logger = [:active_support_logger]
  config.release = "nemo@#{Cnfg.system_version}"
end
