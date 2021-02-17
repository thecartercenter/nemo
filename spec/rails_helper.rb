# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
require "rspec/rails"
require "rspec/collection_matchers"
require "capybara/rspec"
require "capybara/rails"
require "selenium-webdriver"
require "capybara-screenshot/rspec"
require "cancan/matchers"
require "fileutils"
require "vcr"

# Automatically downloads chromedriver, which is used use for JS feature specs
require "webdrivers/chromedriver"

Capybara.register_driver(:selenium_chrome_headless) do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[disable-gpu no-sandbox] + (ENV["HEADED"] ? [] : ["headless"]),
    loggingPrefs: {browser: "ALL", client: "ALL", driver: "ALL", server: "ALL"}
  )

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options).tap do |driver|
    driver.browser.manage.window.size = Selenium::WebDriver::Dimension.new(1280, 2048)
  end
end

Capybara.javascript_driver = :selenium_chrome_headless

# Add support for Headless Chrome screenshots.
Capybara::Screenshot.register_driver(:selenium_chrome_headless) do |driver, path|
  driver.browser.save_screenshot(path)
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

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

  config.define_derived_metadata(file_path: Regexp.new("/spec/destroyers/")) do |metadata|
    metadata[:type] = :model
  end
  config.infer_spec_type_from_file_location!

  config.include(AssertDifference)
  config.include(FeatureSpecHelpers, type: :feature)
  config.include(GeneralSpecHelpers)
  config.include(ModelSpecHelpers, type: :model)
  config.include(RequestSpecHelpers, type: :request)

  config.before(:suite) do
    # In CI environments, the SCSS preprocessor won't have been run because the developer won't have
    # done it and assets:precompile won't have been run. This could lead to issues with feature specs.
    Themeing::ScssPreprocessor.new.run
  end

  # Make sure we have a tmp dir as some specs rely on it.
  config.before(:suite) do
    FileUtils.mkdir_p(Rails.root.join("tmp"))
  end

  # We have to use around so that this block runs before arounds and befores in actual specs.
  config.around(:each) do |example|
    # Previous specs might leave locale set to something else, which can cause issues.
    I18n.locale = :en

    # Ensure no leftover logged in user.
    ENV.delete("TEST_LOGGED_IN_USER_ID")

    example.run
  end

  config.before(:each) do
    # This is the root setting, which is seed data so it should always be available.
    # It's in a before block because it needs to come after DatabaseCleaners things, which
    # are in before blocks. If it goes in the above around block, it runs too early and doesn't get cleaned.
    # If this causes issues, a solution might be to change the DatabaseCleaner initializer to use
    # around blocks.
    create(:setting, mission: nil)
  end

  # Print browser logs to console if they are non-empty.
  # You MUST use console.warn or console.error for this to work.
  config.after(:each, type: :feature, js: true) do
    logs = page.driver.browser.manage.logs.get(:browser).join("\n")
    unless logs.strip.empty?
      puts "------------ BROWSER LOGS -------------"
      puts logs
      puts "---------------------------------------"
    end
  end

  ActionMailer::Base.default_url_options = Cnfg.url_options

  VCR.configure do |c|
    c.cassette_library_dir = "spec/cassettes"
    c.hook_into(:webmock)
    c.default_cassette_options = {
      match_requests_on: %i[method uri host path body],
      allow_unused_http_interactions: false
    }

    # We have to ignore 127.0.0.1 b/c capybara makes all sorts of requests to it.
    c.ignore_hosts("127.0.0.1")

    # Make VCR ignore download of chromedriver by webdrivers gem.
    c.ignore_hosts("chromedriver.storage.googleapis.com")

    c.configure_rspec_metadata!
  end
end
