# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

# Add this to load Capybara integration:
require 'capybara/rspec'
require 'capybara/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end

# Encodes credentials for basic auth
def encode_credentials(username, password)
  "Basic #{Base64.encode64("#{username}:#{password}")}"
end

def submit_xml_response(params_or_xml)
  params = params_or_xml.is_a?(Hash) ? params_or_xml : {}
  params[:xml] = params_or_xml.is_a?(String) ? params_or_xml : params[:xml]

  # Wrap xml with data tag, etc.
  form_info = @form ? "id=\"#{@form.id}\" version=\"#{@form.current_version.sequence}\"" : ''
  xml = %Q{<?xml version='1.0' ?><data #{form_info}
    xmlns:jrm="http://dev.commcarehq.org/jr/xforms" xmlns="http://openrosa.org/formdesigner/240361">
    #{params[:xml]}</data>}

  # Upload the fixture file
  FileUtils.mkpath('test/fixtures')
  fixture_file = 'test/fixtures/test.xml'
  File.open(fixture_file.to_s, 'w'){|f| f.write(xml)}
  uploaded = fixture_file_upload(fixture_file, 'text/xml')

  # Build headers and do post
  headers = params[:user] ? {'HTTP_AUTHORIZATION' => encode_credentials(params[:user].login, 'password')} : {}
  post(@submission_url, {:xml_submission_file => uploaded, :format => 'xml'}, headers)
end
