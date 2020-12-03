# frozen_string_literal: true

ELMO::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Allow local puma-dev domains.
  config.hosts << "nemo.test"

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  # If you want to override this long-term, please do it privately in `local_config.rb`.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :mem_cache_store, {namespace: "v1",
                                            compress: true,
                                            # See the dev setup guide for info on configuring memcached.
                                            value_max_bytes: 16.megabytes,
                                            error_when_over_max_size: true}
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # Where to store uploaded files (see config/storage.yml for options).
  storage_type = ENV["NEMO_STORAGE_TYPE"] || Settings.paperclip&.storage
  config.active_storage.service = storage_type == "cloud" ? :amazon : :local

  # Care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.delivery_method = :letter_opener

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  config.action_view.raise_on_missing_translations = false
  config.i18n.fallbacks = false

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.action_view.logger = nil

  # Uncomment to enable stack traces for deprecation warnings.
  # ActiveSupport::Deprecation.debug = true

  config.to_prepare do
    # # [Performance] Uncomment to profile specific methods.
    # Rack::MiniProfiler.profile_method(User, :foo) { "executing foo" }
    #
    # # Reduce the sample rate if your browser is slow
    # # (default: 0.5 ms; moderate: 5 ms; fast and rough: 10-20 ms).
    # Rack::MiniProfiler.config.flamegraph_sample_rate = 10
  end

  config.after_initialize do
    # # [Performance] Uncomment for automatic n+1 query alerts.
    # Bullet.enable = true
    # Bullet.bullet_logger = true # log/bullet.log
    # Bullet.console = true
    # Bullet.rails_logger = true
  end

  # React development variant (unminified).
  config.react.variant = :development
end
