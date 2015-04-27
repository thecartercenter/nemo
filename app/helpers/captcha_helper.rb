module CaptchaHelper
  def captcha_enabled?
    Recaptcha.configuration.public_key.present?
  end
end
