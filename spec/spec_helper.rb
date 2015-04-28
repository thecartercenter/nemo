# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Add this to load Capybara integration:
require 'capybara/rspec'
require 'capybara/rails'
require 'capybara/poltergeist'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,
    extensions: [File.expand_path("../support/phantomjs_ext/geolocation.js", __FILE__)])
end

Capybara.javascript_driver = :poltergeist

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

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.infer_spec_type_from_file_location!

  config.include AssertDifference
  config.include RequestSpecHelpers, type: :request
  config.include FeatureSpecHelpers, type: :feature

  # Locale should be reset to :en after each test if it is changed.
  config.after(:each) do
    puts "WARNING: I18n locale was left as #{I18n.locale}" unless I18n.locale = :en
  end

  # Temporarily disabling feature specs because they're broken.
  config.filter_run_excluding type: :feature
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
