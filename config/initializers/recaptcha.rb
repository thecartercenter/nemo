# frozen_string_literal: true

# Ensure that the reCAPTCHA keys have been set after all initializers finish
ELMO::Application.config.after_initialize do
  Recaptcha.configuration.tap do |config|
    unless config.public_key.present? && config.private_key.present?
      raise "Missing reCAPTCHA keys. See local_config.rb.example for configuration guidance."
    end
  end
end
