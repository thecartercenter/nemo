# frozen_string_literal: true

# Recaptcha public and private keys should be set with the RECAPTCHA_PUBLIC_KEY
# and RECAPTCHA_PRIVATE_KEY environment variables, or in local_config.rb
Recaptcha.configure do |config|
  config.api_version = "v2"
end

# Ensure that the reCAPTCHA keys have been set after all initializers finish
ELMO::Application.config.after_initialize do
  Recaptcha.configuration.tap do |config|
    unless config.public_key.present? && config.private_key.present?
      raise "Missing reCAPTCHA keys. See local_config.rb.example for configuration guidance."
    end
  end
end
