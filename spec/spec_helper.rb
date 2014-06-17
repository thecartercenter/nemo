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

def submit_j2me_response(params)
  raise 'form must have version' unless @form.current_version

  # Add all the extra stuff that J2ME adds to the data hash
  params[:data]['id'] = @form.id.to_s
  params[:data]['uiVersion'] = '1'
  params[:data]['version'] = @form.current_version.sequence
  params[:data]['name'] = @form.name
  params[:data]['xmlns:jrm'] = 'http://dev.commcarehq.org/jr/xforms'
  params[:data]['xmlns'] = "http://openrosa.org/formdesigner/#{@form.current_version.sequence}"

  # If we are doing a normally authenticated submission, add credentials.
  headers = params[:auth] ? {'HTTP_AUTHORIZATION' => encode_credentials(@user.login, 'password')} : {}

  post(@submission_url, params.slice(:data), headers)
end

# helper method to parse json and make keys symbols
def parse_json(body)
  JSON.parse(body, symbolize_names: true)
end

# Currently duplicated in test/test_helper until it becomes obvious how to refactor.
def login(user)
  post(user_session_path, :user_session => {:login => user.login, :password => "password"})
  follow_redirect!
  assert_response(:success)

  # reload the user since some stuff may have changed in database (e.g. current_mission) during login process
  user.reload
end
