# frozen_string_literal: true

# Check key settings in production to make sure they have safe and sensible values.

if Rails.env.production?
  secret_key_base = Rails.configuration.secret_key_base
  if secret_key_base.blank? || secret_key_base.match?(/XXXXXXXXXXXXXXXX/)
    abort("NEMO_SECRET_KEY_BASE must be set to a real value")
  end
end
