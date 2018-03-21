puts '--------------------'
puts !configatron.offline_mode, 'mode'
puts configatron.url.host.nil?, 'host'
puts '--------------------'
if !configatron.offline_mode && configatron.url.host.nil?
  raise "Host is required when offline mode is false. See local_config.rb.example for configuration guidance."
end
