# frozen_string_literal: true

require_relative("boot")

require "rails/all"
require "coffee_script"

# Load this here so that the Cnfg global is available.
require_relative "../lib/config_manager"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ELMO
  # Application-wide settings and setup.
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults(6.0)

    config.secret_key_base = Cnfg.secret_key_base

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # add concerns folders to autoload paths
    config.autoload_paths += Dir[
      Rails.root.join("app/controllers/concerns"),
      Rails.root.join("app/models/concerns")
    ]

    # Overrides are manually required below.
    Rails.autoloaders.main.ignore(
      Rails.root.join("app/overrides"),
      Rails.root.join("lib/enketo-transformer-service")
    )

    config.eager_load_paths += Dir[
      # Zeitwerk wants us to eager_load lib instead of autoloading.
      Rails.root.join("lib")
    ]

    # Zeitwerk uses absolute paths internally, and applications running in :zeitwerk mode
    # do not need require_dependency, so models, controllers, jobs, etc. do not need to be
    # in $LOAD_PATH. Setting this to false saves Ruby from checking these directories when
    # resolving require calls with relative paths.
    config.add_autoload_paths_to_load_path = false

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
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]

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

    # This should be enabled eventually when our code supports it. But for now, enabling this breaks
    # things because some code expects model cache keys to have updated timestamps, which go away
    # when cache versioning is enabled.
    config.active_record.cache_versioning = false

    # Default expiry for attachments.
    config.active_storage.service_urls_expire_in = 1.hour

    # For security.
    config.action_dispatch.default_headers = {"X-Frame-Options" => "DENY"}

    # Restrict available locales to defined system locales.
    # Without this, it returns a whole bunch more defined by i18n-js.
    # This is different from preferred_locales, which is part of the mission settings class and represents
    # locales that questions, options, etc. may be defined in.
    I18n.available_locales = %i[en fr es ar ko pt pt-BR]

    # This was initially added to allow overriding the odata_server engine.
    # https://edgeguides.rubyonrails.org/engines.html#overriding-models-and-controllers
    config.to_prepare do
      Dir.glob(Rails.root.join("app/overrides/**/*_override.rb")).each do |override|
        load override
      end
    end

    if Cnfg.recaptcha_public_key.present?
      Recaptcha.configure do |config|
        config.public_key = Cnfg.recaptcha_public_key
        config.private_key = Cnfg.recaptcha_private_key
      end
    end
  end
end
