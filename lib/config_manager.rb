# frozen_string_literal: true

# Lightweight class to hold app configuration.
class ConfigManager
  include Singleton

end

Cnfg = ConfigManager.instance
