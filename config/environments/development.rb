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

  # Caching may need to be turned on when testing caching itself. If so, please use
  # config/initializers/local_config.rb to override this value,
  # or change it here but please don't commit the change!
  config.action_controller.perform_caching = false

  # This is here only in case the above value is overridden as described.
  config.cache_store = :dalli_store, nil, { value_max_bytes: 2.megabytes }

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
  # bullet gem for query optimization
  # config.after_initialize do
  #   Bullet.enable = true
  #   Bullet.bullet_logger = true
  #   Bullet.console = true
  #   Bullet.rails_logger = true
  # end

  # React development variant (unminified)
  config.react.variant = :development
end
