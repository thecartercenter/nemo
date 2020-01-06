# frozen_string_literal: true

if !configatron.offline_mode && configatron.url.host.nil?
  raise "Host is required when offline mode is false. See local_config.rb.example for configuration guidance."
end
