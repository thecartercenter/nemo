# frozen_string_literal: true

# Check key settings in production to make sure they have safe and sensible values.

# rubocop:disable Style/IfUnlessModifier
if Rails.env.production?
  secret_key_base = Rails.configuration.secret_key_base
  if secret_key_base.blank? || secret_key_base.match?(/XXXXXXXXXXXXXXXX/)
    abort("NEMO_SECRET_KEY_BASE must be set to a real value")
  end

  if Cnfg.url_protocol == "http"
    abort("NEMO_URL_PROTOCOL must be https in production")
  end

  if Cnfg.url_host.match?(/example.com/)
    abort("NEMO_URL_HOST must be set to real value in production")
  end

  if Cnfg.url_port != 443 && !ENV["NEMO_URL_USE_CUSTOM_PORT"]
    abort("NEMO_URL_PORT must be set to 443 in production unless NEMO_URL_USE_CUSTOM_PORT is set")
  end

  unless Cnfg.offline_mode?
    if Cnfg.site_email.match?(/example.com/)
      abort("NEMO_SITE_EMAIL must be set to real value in production")
    end

    if Cnfg.webmaster_emails.join.match?(/example.com/)
      abort("NEMO_WEBMASTER_EMAILS must be set to real value in production")
    end

    if Cnfg.recaptcha_public_key.match?(/yyyyyyyy/)
      abort("NEMO_RECAPTCHA_PUBLIC_KEY must be set to real value in production")
    end

    if Cnfg.recaptcha_public_key.match?(/xxxxxxxx/)
      abort("NEMO_RECAPTCHA_PRIVATE_KEY must be set to real value in production")
    end

    if Cnfg.google_maps_key.match?(/XXXXXXXX/)
      abort("NEMO_GOOGLE_MAPS_API_KEY must be set to real value in production")
    end
  end

  if Cnfg.allow_missionless_sms? && Cnfg.universal_sms_token.match?(/XXXXXXXX/)
    abort("NEMO_UNIVERSAL_SMS_TOKEN must be set to real value if NEMO_ALLOW_MISSIONLESS_SMS is true")
  end
end
# rubocop:enable Style/IfUnlessModifier
