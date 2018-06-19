# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails/all"
require "coffee_script"

Bundler.require(*Rails.groups)

module ELMO
  # Application-wide settings and setup.
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # add concerns folders to autoload paths
    config.autoload_paths += [
      "#{config.root}/app/controllers/concerns",
      "#{config.root}/app/controllers/concerns/application_controller",
      "#{config.root}/app/models/concerns",
      "#{config.root}/lib"
    ]

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # default to eastern -- this will be overwritten if there is a timezone setting in the DB
    config.time_zone = "Eastern Time (US & Canada)"

    # be picky about available locales
    config.i18n.enforce_available_locales = false

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += %i[password password_confirmation
                                   twilio_account_sid twilio_auth_token frontlinecloud_api_key
                                   session warden secret salt cookie csrf user_credentials session_id data]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = "1.0"

    # Use Delayed::Job as the ActiveJob queue adapter
    config.active_job.queue_adapter = :delayed_job

    config.generators do |g|
      g.test_framework :rspec
      g.integration_framework :rspec
      g.orm :active_record, primary_key_type: :uuid
    end

    config.active_record.time_zone_aware_types = [:datetime]

    ####################################
    # CUSTOM SETTINGS
    ####################################

    # NOTE: Don't add anymore configatron settings. Use settings.yml instead.

    # read system version from file
    configatron.system_version = File.read(Rails.root.join("VERSION")).strip

    # regular expressions
    configatron.lat_lng_regexp = /^(-?\d+(\.\d+)?)\s*[,;:\s]\s*(-?\d+(\.\d+)?)/

    # locales with full translations (I18n.available_locales returns a whole bunch more defined by i18n-js)
    configatron.full_locales = %i[en fr es ar ko]

    # Of the locales in full_locales, the ones displayed RTL.
    configatron.rtl_locales = %i[ar]

    # For security.
    config.action_dispatch.default_headers = {"X-Frame-Options" => "DENY"}

    # requests-per-minute limit for ODK Collect endpoints
    configatron.direct_auth_request_limit = 30

    # logins-per-minute threshold for showing a captcha
    configatron.login_captcha_threshold = 30

    # default timeout for sensitive areas requiring a password reprompt
    configatron.recent_login_max_age = 60.minutes

    # We use \r\n for CSV row separator because Excel seems to prefer it.
    configatron.csv_row_separator = "\r\n"

    # Restrict available locales to defined system locales
    # This should replace `configatron.full_locales` eventually
    # assuming this caused no further issues
    I18n.available_locales = configatron.full_locales

    # This is the default. It can be overridden in local_config.rb, which comes later.
    configatron.offline_mode = false
  end
end
