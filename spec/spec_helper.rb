# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
require "rspec/collection_matchers"
require "capybara/rspec"
require "capybara/rails"
require "selenium-webdriver"
require "capybara-screenshot/rspec"
require "paperclip/matchers"
require "cancan/matchers"
require "fileutils"

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[disable-gpu no-sandbox] + (ENV["HEADED"] ? [] : ["headless"]),
    loggingPrefs: {browser: "ALL", client: "ALL", driver: "ALL", server: "ALL"}
  )

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options).tap do |driver|
    driver.browser.manage.window.size = Selenium::WebDriver::Dimension.new(1280, 1024)
  end
end

Capybara.javascript_driver = :selenium_chrome_headless

# Add support for Headless Chrome screenshots.
Capybara::Screenshot.register_driver(:selenium_chrome_headless) do |driver, path|
  driver.browser.save_screenshot(path)
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec", "support", "**", "*.rb")].each { |f| require f }

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
  config.include FeatureSpecHelpers, type: :feature
  config.include GeneralSpecHelpers
  config.include ModelSpecHelpers, type: :model
  config.include Paperclip::Shoulda::Matchers
  config.include RequestSpecHelpers, type: :request

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

    # This setting is used in Translatable and can lead to weird results if it's set to
    # something other than [:en] by a previous spec.
    configatron.preferred_locales = [:en]

    example.run
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

  # Important that url options are consistent for specs regardless of what's in local config.
  configatron.url.host = "www.example.com"
  configatron.url.protocol = "http"
  configatron.url.port = nil
  ActionMailer::Base.default_url_options = configatron.url.to_h.slice(:host, :port, :protocol)
end
