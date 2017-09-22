Rails.configuration.middleware.use ExceptionNotification::Rack, email: {
  email_prefix: "[ELMO ERROR] ",
  sender_address: configatron.site_email,
  exception_recipients: configatron.webmaster_emails
}
