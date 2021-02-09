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
end

Cnfg = ConfigManager.instance
