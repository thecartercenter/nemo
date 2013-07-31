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
  
  # helper that sets up a new form with the given parameters
  def setup_form(options)
    # default question required option
    options[:required] ||= false
    options[:mission] ||= get_mission
    
    @form = FactoryGirl.create(:form, :smsable => true, :mission => options[:mission])
    options[:questions].each do |type|
      # create the question
      q = FactoryGirl.build(:question, :code => "q#{rand(1000000)}", :qtype_name => type, :mission => options[:mission])
      
      # add an option set if required
      if %w(select_one select_multiple).include?(type)
        # put options in weird order to ensure the order stuff works ok
        q.option_set = FactoryGirl.create(:option_set, :name => "Options", :option_names => %w(A B C D E), :mission => options[:mission])
      end
      
      q.save!
      
      # add it to the form
      @form.questionings.create(:question => q, :required => options[:required])
    end
    @form.publish!
    @form.reload
  end
end
