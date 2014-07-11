RSpec.configure do |config|
  config.before :each, type: :request do
    if defined?(app)
      app.default_url_options = { :locale => I18n.locale || I18n.default_locale, :mode => nil }
    end
  end
end
