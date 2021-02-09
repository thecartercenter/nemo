# frozen_string_literal: true

# Lightweight class to hold app configuration.
class ConfigManager
  include Singleton

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
end

Cnfg = ConfigManager.instance
