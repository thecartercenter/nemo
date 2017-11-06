# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/collection_matchers'

# Add this to load Capybara integration:
require 'capybara/rspec'
require 'capybara/rails'
require 'capybara/poltergeist'
require 'capybara-screenshot/rspec'
require 'paperclip/matchers'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,
    phantomjs_options: ['--ignore-ssl-errors=yes'],
    extensions: [File.expand_path("../support/phantomjs_ext/geolocation.js", __FILE__)])
end

Capybara.register_driver :poltergeist_debug do |app|
  Capybara::Poltergeist::Driver.new(app, inspector: true,
    phantomjs_options: ['--ignore-ssl-errors=yes'],
    extensions: [File.expand_path("../support/phantomjs_ext/geolocation.js", __FILE__)])
end

Capybara.javascript_driver = :poltergeist

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # persist example status
  config.example_status_persistence_file_path = "log/rspec-status.log"

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
  config.include GeneralSpecHelpers
  config.include MediaSpecHelpers::FileHandling
  config.include ModelSpecHelpers, type: :model
  config.include RequestSpecHelpers, type: :request
  config.include FeatureSpecHelpers, type: :feature
  config.include AssertSelectRoot, type: :request
  config.include Paperclip::Shoulda::Matchers

  config.before(:each) do
    # Previous specs might leave locale set to something else, which can cause issues.
    I18n.locale = :en

    # This setting is used in Translatable and can lead to weird results if it's set to
    # something other than [:en] by a previous spec.
    configatron.preferred_locales = [:en]
  end

  # Locale should be reset to :en after each test if it is changed.
  # TODO: Is this still necessary if we are resetting to :en above each time?
  config.after(:each) do
    puts "WARNING: I18n locale was left as #{I18n.locale}" unless I18n.locale = :en
  end

  # Important that url options are consistent for specs regardless of what's in local config.
  configatron.url.host = "www.example.com"
  configatron.url.protocol = "http"
  configatron.url.port = nil
  ActionMailer::Base.default_url_options = configatron.url.to_h.slice(:host, :port, :protocol)
end
