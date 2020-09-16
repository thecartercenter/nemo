# frozen_string_literal: true

ELMO::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports
  config.consider_all_requests_local = true

  # Caching may need to be turned on when testing caching itself.
  # To do so, you can run `rails dev:cache` which will create this tempfile.
  # If you want to override this long-term, please do it privately in `local_config.rb`.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.cache_store = :dalli_store, nil, {namespace: "v1",
                                             compress: true,
                                             # See the dev setup guide for info on configuring memcached.
                                             value_max_bytes: 2.megabytes,
                                             error_when_over_max_size: true}
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.delivery_method = :letter_opener

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = false

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = false
  config.i18n.fallbacks = false

  config.action_view.logger = nil

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

  # React development variant (unminified)
  config.react.variant = :development
end
