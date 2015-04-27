# Recaptcha public and private keys should be set with the RECAPTCHA_PUBLIC_KEY
# and RECAPTCHA_PRIVATE_KEY environment variables, or in local_config.rb
Recaptcha.configure do |config|
  config.api_version = 'v2'
end
