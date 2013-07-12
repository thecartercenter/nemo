ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  
  setup :set_locale_in_url_options

  # sets the locale in the url options to the current locale for integration tests
  # this is also done in application_controller but needs to be done here too for some reason
  def set_locale_in_url_options
    app.default_url_options = { :locale => I18n.locale } if defined?(app)
  end
  
  # logs in the given user
  # we assume that the password is 'password'
  def login(user)
    post_via_redirect(user_session_path, :user_session => {:login => user.login, :password => "password"})
  end
end
