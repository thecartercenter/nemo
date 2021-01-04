# frozen_string_literal: true

# Lightweight class to hold app configuration.
class ConfigManager
  include Singleton

  def site_name(theme)
    ENV["NEMO_#{theme}_THEME_SITE_NAME"] || "NEMO"
  end
end

Cnfg = ConfigManager.instance
