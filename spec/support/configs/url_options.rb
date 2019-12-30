# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :request) do
    app.default_url_options = {locale: I18n.locale || I18n.default_locale, mode: nil} if defined?(app)
  end
end
