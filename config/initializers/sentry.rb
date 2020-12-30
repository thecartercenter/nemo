# frozen_string_literal: true

Sentry.init do |config|
  next if Rails.env.test?

  config.dsn = "https://a81af08ff85042f3ae314e6c685853a3@o448595.ingest.sentry.io/5430181"
  config.breadcrumbs_logger = [:active_support_logger]
  config.release = "nemo@#{configatron.system_version}"
end
