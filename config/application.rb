# frozen_string_literal: true

require_relative("boot")

require "rails/all"
require "coffee_script"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ELMO
  # Application-wide settings and setup.
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults(6.0)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # add concerns folders to autoload paths
    config.autoload_paths += %W[
      #{config.root}/app/controllers/concerns
      #{config.root}/app/controllers/concerns/application_controller
      #{config.root}/app/models/concerns
      #{config.root}/lib
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

    # Intent: Don't use the asset pipeline (sprockets).
    #
    # Reality: This seems to change nothing at all,
    # not even bundle size or output hash for completely clean builds.
    # Something MUST be overriding it, but the documentation on it is sparse.
    config.assets.enabled = false

    # Include images from vendor/assets/ too https://stackoverflow.com/a/14195512/763231
    config.assets.precompile += %w[*.png *.jpg *.jpeg *.gif *.svg]

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = "1.0"

    # Use Delayed::Job as the ActiveJob queue adapter
    config.active_job.queue_adapter = :delayed_job

    config.generators do |g|
      g.test_framework(:rspec)
      g.integration_framework(:rspec)
      g.orm(:active_record, primary_key_type: :uuid)
    end

    config.active_record.time_zone_aware_types = [:datetime]

    # Require `belongs_to` associations by default.
    config.active_record.belongs_to_required_by_default = false

    ####################################
    # CUSTOM SETTINGS
    ####################################

    # NOTE: Don't add anymore configatron settings. Use settings.yml instead.

    # read system version from file
    configatron.system_version = File.read(Rails.root.join("VERSION")).strip

    # locales with full translations (I18n.available_locales returns a whole bunch more defined by i18n-js)
    configatron.full_locales = %i[en fr es ar ko pt pt-BR]

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

    # Restrict available locales to defined system locales
    # This should replace `configatron.full_locales` eventually
    # assuming this caused no further issues
    I18n.available_locales = configatron.full_locales

    # This is the default. It can be overridden in local_config.rb, which comes later.
    configatron.offline_mode = false

    # Error reporting via Sentry (formerly Raven).
    Raven.configure do |config|
      next if Rails.env.test?
      config.dsn = "https://a81af08ff85042f3ae314e6c685853a3@o448595.ingest.sentry.io/5430181"
    end

    # This was initially added to allow overriding the odata_server engine.
    # https://edgeguides.rubyonrails.org/engines.html#overriding-models-and-controllers
    config.to_prepare do
      Dir.glob(Rails.root.join("app", "overrides", "**", "*_override.rb")).each do |override|
        require_dependency override
      end
    end
  end
end
