# frozen_string_literal: true

# Runs after local_config.rb and loads from ENV if ENV var is defined.
# Designed to be used instead of local_config.rb, as a way to start phasing out the latter.

def env_var_if_set(key, default = nil)
  if ENV.key?(key)
    yield(ENV[key])
  elsif !default.nil?
    yield(default)
  end
end

env_var_if_set("NEMO_SECRET_KEY_BASE") { |v| ELMO::Application.config.secret_key_base = v }
env_var_if_set("NEMO_OFFLINE_MODE") { |v| configatron.offline_mode = v == "true" }
env_var_if_set("NEMO_URL_HOST") { |v| configatron.url.host = v }
env_var_if_set("NEMO_URL_PROTOCOL", "https") { |v| configatron.url.protocol = v }
env_var_if_set("NEMO_URL_PORT") { |v| configatron.url.port = v }
env_var_if_set("NEMO_GOOGLE_MAPS_API_KEY") { |v| configatron.google_maps_api_key = v }
env_var_if_set("NEMO_UNIVERSAL_SMS_TOKEN") { |v| configatron.universal_sms_token = v }
env_var_if_set("NEMO_SCOUT_KEY") { |v| configatron.scout.key = v }
env_var_if_set("NEMO_WEBMASTER_EMAILS") { |v| configatron.webmaster_emails = v.split(/\s+,\s+/) }
env_var_if_set("NEMO_FROM_EMAIL") { |v| configatron.site_email = %(NEMO <#{v}>) }

if ENV.key?("NEMO_RECAPTCHA_PUBLIC_KEY")
  Recaptcha.configure do |config|
    env_var_if_set("NEMO_RECAPTCHA_PUBLIC_KEY") { |v| config.public_key = v }
    env_var_if_set("NEMO_RECAPTCHA_PRIVATE_KEY") { |v| config.private_key = v }
  end
end

if ENV.key?("NEMO_SMTP_ADDRESS")
  ActionMailer::Base.smtp_settings = {
    address: ENV["NEMO_SMTP_ADDRESS"].presence,
    port: ENV["NEMO_SMTP_PORT"].presence&.to_i || 587,
    authentication: ENV["NEMO_SMTP_AUTH_TYPE"].presence&.to_sym || :plain,
    user_name: ENV["NEMO_SMTP_USERNAME"].presence,
    password: ENV["NEMO_SMTP_PASSWORD"].presence
  }
end
