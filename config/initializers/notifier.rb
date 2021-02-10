# frozen_string_literal: true

# Also, while it may seem counterintuitive, it's important the middleware be enabled for test mode
# because there are tests that test its behavior.
unless Rails.env.development? || Cnfg.offline_mode?
  Rails.configuration.middleware.use(ExceptionNotification::Rack, email: {
    email_prefix: "[#{Cnfg.url_host} ERROR] ",
    sender_address: Cnfg.site_email_with_name,
    exception_recipients: Cnfg.webmaster_emails,

    # Not including session because it contains user_credentials, not sure if that's secret,
    # and adding it to the filter did not work.
    sections: %w[request environment backtrace]
  })
end
