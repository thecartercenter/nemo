# frozen_string_literal: true

# Assumes a local_config.rb file still exists and has set some local settings that we want to move
# to .env.
# rubocop:disable Style/GuardClause
class MoveConfigatronSettingsToDotEnv < ActiveRecord::Migration[6.1]
  def up
    to_write = {}

    if configatron.key?(:webmaster_emails)
      emails = configatron.webmaster_emails.reject { |e| e.match?(/example.com/) }
      to_write[:NEMO_WEBMASTER_EMAILS] = emails.join(",") unless emails.empty?
    end

    if configatron.key?(:url)
      %i[host protocol port].each do |k|
        to_write[:"NEMO_URL_#{k.upcase}"] = configatron.url[k] if configatron.url.key?(k)
      end
    end
    to_write[:NEMO_URL_PROTOCOL] ||= "https"
    to_write[:NEMO_URL_PORT] ||= "443"

    if configatron.key?(:google_maps_api_key) && !configatron.google_maps_api_key.match?("XXXX")
      to_write[:NEMO_GOOGLE_MAPS_API_KEY] = configatron.google_maps_api_key
    end

    if configatron.key?(:scout) && configatron.scout.key?(:key)
      to_write[:NEMO_SCOUT_KEY] = configatron.scout.key
    end

    if configatron.key?(:site_email) && !configatron.site_email.match?(/example.com/)
      email = configatron.site_email
      if (matches = email.match(/<(.+)>/))
        email = matches[1]
      end
      to_write[:NEMO_SITE_EMAIL] = email
    end

    if configatron.key?(:offline_mode)
      to_write[:NEMO_OFFLINE_MODE] = configatron.offline_mode ? "true" : "false"
    end

    if configatron.key?(:universal_sms_token) && !configatron.universal_sms_token.match?(/xxxxxxxx/)
      to_write[:NEMO_ALLOW_MISSIONLESS_SMS] = "true"
      to_write[:NEMO_UNIVERSAL_SMS_TOKEN] = configatron.universal_sms_token
    end

    to_write[:NEMO_SECRET_KEY_BASE] = ELMO::Application.config.secret_key_base

    smtp_settings = ELMO::Application.config.action_mailer.smtp_settings
    %i[address port authentication user_name password].each do |k|
      to_write[:"NEMO_SMTP_#{k.to_s.upcase}"] = smtp_settings[k] if smtp_settings[k].present?
    end

    unless Recaptcha.configuration.public_key.match?(/(xxx|yyy)/i)
      to_write[:NEMO_RECAPTCHA_PUBLIC_KEY] = Recaptcha.configuration.public_key
    end
    unless Recaptcha.configuration.private_key.match?(/xxx|yyy/i)
      to_write[:NEMO_RECAPTCHA_PRIVATE_KEY] = Recaptcha.configuration.private_key
    end

    write_local_config_deprecation
    write_to_env(to_write)
  end

  private

  def write_local_config_deprecation
    local_conf_path = Rails.root.join("config/initializers/local_config.rb")
    return unless File.exist?(local_conf_path)
    contents = File.read(local_conf_path)
    return if contents.match?(/\A# DEPRECATED/)
    notice = "# DEPRECATED: This file is no longer used. "\
      "Its values have been copied to .env.#{Rails.env}.local.\n\n\n\n"
    File.open(local_conf_path, "w") { |f| f.write("#{notice}#{contents}") }
  end

  def write_to_env(to_write)
    env_path = Rails.root.join(".env.#{Rails.env}.local")
    existing = File.read(env_path)
    begin_marker = "### BEGIN MIGRATED CONFIG ###"
    end_marker = "### END MIGRATED CONFIG ###"
    lines = to_write.map { |k, v| "#{k}=#{v}" }.join("\n")
    migrated = "#{begin_marker}\n#{lines}\n#{end_marker}\n"
    bits = existing.split(/\s*### BEGIN MIGRATED CONFIG ###.+### END MIGRATED CONFIG ###\s*/m)
    existing = bits.map(&:strip).join("\n")
    File.open(env_path, "w") { |f| f.write("#{existing}\n\n#{migrated}") }
  end
end
# rubocop:enable Style/GuardClause
