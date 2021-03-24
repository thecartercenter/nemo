# frozen_string_literal: true

# Lightweight class to hold app configuration.
class ConfigManager
  include Singleton

  def secret_key_base
    ENV.fetch("NEMO_SECRET_KEY_BASE")
  end

  def offline_mode?
    ENV["NEMO_OFFLINE_MODE"] == "true"
  end

  # read system version from file
  def system_version
    @system_version ||= File.read(Rails.root.join("VERSION")).strip
  end

  # Locales we support that are displayed right-to-left.
  def rtl_locales
    %i[ar]
  end

  def site_name(theme = nil)
    theme ||= "NEMO"
    ENV["NEMO_#{theme.upcase}_THEME_SITE_NAME"] || "NEMO"
  end

  def site_email_with_name(theme = nil)
    "#{site_name(theme)} <#{site_email}>"
  end

  def site_email
    ENV.fetch("NEMO_SITE_EMAIL")
  end

  # Returns an array of email addresses.
  def webmaster_emails
    ENV.fetch("NEMO_WEBMASTER_EMAILS").split(/\s+,\s+/)
  end

  def max_upload_size_mib
    ENV.fetch("NEMO_MAX_UPLOAD_SIZE_MIB").to_i
  end

  def url_protocol
    ENV.fetch("NEMO_URL_PROTOCOL")
  end

  def url_host
    ENV.fetch("NEMO_URL_HOST")
  end

  def url_port
    ENV.fetch("NEMO_URL_PORT").to_i
  end

  # Returns a hash of url options (port, protocol, host). Omits port if it's default for protocol.
  def url_options
    options = {protocol: url_protocol, host: url_host}
    return options if url_protocol == "http" && url_port == 80 || url_protocol == "https" && url_port == 443
    options[:port] = url_port
    options
  end

  def smtp_address
    ENV.fetch("NEMO_SMTP_ADDRESS")
  end

  def smtp_port
    ENV.fetch("NEMO_SMTP_PORT").to_i
  end

  def smtp_domain
    ENV["NEMO_SMTP_DOMAIN"]
  end

  def smtp_authentication
    ENV["NEMO_SMTP_AUTHENTICATION"]&.to_sym
  end

  def smtp_user_name
    ENV["NEMO_SMTP_USER_NAME"]
  end

  def smtp_password
    ENV["NEMO_SMTP_PASSWORD"]
  end

  # Returns a hash of SMTP options, omitting anything that's blank
  # (otherwise, e.g. if `domain` is `nil` then all messages will be rejected).
  def smtp_options
    {
      address: smtp_address,
      port: smtp_port,
      domain: smtp_domain,
      authentication: smtp_authentication,
      user_name: smtp_user_name,
      password: smtp_password
    }.select { |_key, value| value.presence }
  end

  def google_maps_key
    ENV["NEMO_GOOGLE_MAPS_API_KEY"]
  end

  def scout_key
    ENV["NEMO_SCOUT_KEY"]
  end

  def sentry_dsn
    ENV["NEMO_SENTRY_DSN"]
  end

  def allow_missionless_sms?
    ENV["NEMO_ALLOW_MISSIONLESS_SMS"] == "true"
  end

  def universal_sms_token
    allow_missionless_sms? ? ENV["NEMO_UNIVERSAL_SMS_TOKEN"] : nil
  end

  def recaptcha_public_key
    ENV["NEMO_RECAPTCHA_PUBLIC_KEY"]
  end

  def recaptcha_private_key
    ENV["NEMO_RECAPTCHA_PRIVATE_KEY"]
  end

  def storage_service
    storage_type = ENV.fetch("NEMO_STORAGE_TYPE")
    storage_type == "cloud" ? :amazon : storage_type.to_sym
  end
end

Cnfg = ConfigManager.instance
