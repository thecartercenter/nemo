# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
require "rspec/rails"
require "rspec/collection_matchers"
require "capybara/rspec"
require "capybara/rails"
require "selenium-webdriver"
require "cancan/matchers"
require "fileutils"
require "vcr"

Capybara.register_driver(:selenium_chrome_headless) do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[disable-gpu no-sandbox mute-audio disable-dev-shm-usage] + (ENV["HEADED"] ? [] : ["headless"]),
    "goog:loggingPrefs" => {browser: "ALL", client: "ALL", driver: "ALL", server: "ALL"}
  )

  options.add_preference(:download, default_directory: Capybara.save_path.to_s)

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options).tap do |driver|
    driver.browser.manage.window.size = Selenium::WebDriver::Dimension.new(1280, 2048)
  end
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

  config.define_derived_metadata(file_path: Regexp.new("/spec/destroyers/")) do |metadata|
    metadata[:type] = :model
  end
  config.infer_spec_type_from_file_location!

  config.include(AssertDifference)
  config.include(SystemSpecHelpers, type: :system)
  config.include(GeneralSpecHelpers)
  config.include(ModelSpecHelpers, type: :model)
  config.include(RequestSpecHelpers, type: :request)

  config.before(:suite) do
    # In CI environments, the SCSS preprocessor won't have been run because the developer won't have
    # done it and assets:precompile won't have been run. This could lead to issues with feature specs.
    Themeing::ScssPreprocessor.new.run
  end

  # Make sure we have a tmp dir as some specs rely on it.
  # Test failure screenshots and browser downloads will be saved here.
  config.before(:suite) do
    Capybara.save_path = Rails.root.join("tmp/capybara")
    FileUtils.mkdir_p(Capybara.save_path)
  end

  # Set up system tests
  config.before(:each, type: :system) do
    driven_by(:rack_test)
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end

  # We have to use around so that this block runs before arounds and befores in actual specs.
  config.around(:each) do |example|
    # Previous specs might leave locale set to something else, which can cause issues.
    I18n.locale = :en

    # Ensure no leftover logged in user.
    ENV.delete("TEST_LOGGED_IN_USER_ID")

    Rails::Debug.log("<----- #{example.description} (#{example.location}) ----->")

    begin
      Setting.where(mission: nil).destroy_all
      @_setting = create(:setting, mission: nil)
      example.run
    ensure
      @_setting&.destroy! if @_setting&.persisted?
      Rails::Debug.log("<----- #{example.description} ----->")
      Rails::Debug.log("")
    end
  end

  # Add extra delay for flappers which seems to help for certain browser actions.
  config.around(:each, flapping: true) do |example|
    method_names = {
      visit: Capybara::Session,
      click_on: Capybara::Session,
      click_button: Capybara::Session,
      click: Capybara::Node::Element
    }
    originals = method_names.map { |name, klass| klass.instance_method(name) }

    method_names.each_with_index do |(name, klass), i|
      klass.define_method(name) do |*args, &block|
        result = originals[i].bind(self).call(*args, &block)
        puts "Sleeping for `#{name}`"
        sleep(0.1)
        result
      end
    end

    example.run
  ensure
    # Restore original method
    method_names.each_with_index do |(name, klass), i|
      klass.define_method(name, originals[i])
    end
  end

  # Print browser logs to console if they are non-empty.
  # You MUST use console.warn or console.error for this to work.
  config.after(:each, type: :system, js: true) do
    # logs = page.driver.browser.manage.logs.get(:browser).join("\n")
    logs = ""
    unless logs.strip.empty?
      Rails::Debug.log("<----- START BROWSER LOGS ----->")
      puts logs
      Rails::Debug.log("<----- END BROWSER LOGS ----->")
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
