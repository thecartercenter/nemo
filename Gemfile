# frozen_string_literal: true

source "http://rubygems.org"

# 6.0.3.x has a blocking regression, waiting for a fix since May 2020:
# https://github.com/rails/rails/issues/39173
gem "rails", "~> 6.0.2.2"

# Misc
gem "attribute_normalizer", "~> 1.2"
gem "daemons", "~> 1.2"
gem "descriptive_statistics", "~> 2.5", require: "descriptive_statistics/safe" # mean, median, etc.
gem "draper", "~> 4.0"
gem "eventmachine", "~> 1.2", platform: :ruby
gem "exception_notification", "~> 4.2"
gem "friendly_id", "~> 5.1"
gem "phony", "~> 2.15"
gem "rack-attack", git: "https://github.com/sassafrastech/rack-attack.git"
gem "rake", "~> 13.0"
gem "random_data", "~> 1.6" # Deprecated: Use Faker instead
gem "recaptcha", "~> 3.4", require: "recaptcha/rails" # Small change in v4, we should upgrade eventually.
gem "responders", "~> 3.0"
gem "rqrcode", "~> 1.1"
gem "rubyzip", "~> 2.3"
gem "term-ansicolor", "~> 1.3"
gem "thor", "~> 1.0"
gem "twilio-ruby", "~> 4.2" # Does not use semver after v5, watch out!

# JS/CSS
gem "bootstrap", "~> 4.3"
gem "clipboard-rails", "~> 1.7"
gem "dropzonejs-rails", "~> 0.8.5"
gem "font-awesome-rails", "~> 4.7"
gem "jquery-fileupload-rails", "~> 1.0"
gem "jquery-rails", "~> 4.3"
gem "popper_js", "~> 1.14"
gem "rails-backbone", git: "https://github.com/codebrew/backbone-rails.git"
gem "react-rails", "~> 2.4"
gem "select2-rails", "~> 4.0"
gem "spinjs-rails", "~> 1.3.0" # Breaking changes in v1.4 (spin.js v2.0).
gem "uglifier", "~> 4.2"
gem "webpacker", "~> 4.2"

# Authz and Authn
gem "activerecord-session_store", "~> 1.1"
gem "authlogic", "~> 6.1"
gem "cancancan", "~> 3.1"
gem "draper-cancancan", "~> 1.1"
gem "scrypt", "~> 3.0"

# Spreadsheets
gem "caxlsx", "~> 3.0"
gem "caxlsx_rails", "~> 0.6.2"

# Pagination
gem "will_paginate", "~> 3.1"
gem "will_paginate-bootstrap4", "~> 0.2.2"

# Markdown
gem "bluecloth", "~> 2.2"
gem "rdiscount", "~> 2.1"
gem "reverse_markdown", "~> 2.0"

# Storage
gem "fog-aws", "~> 3.3"
gem "paperclip", "~> 6.0"

# API
gem "api-pagination", "~> 4.1"
gem "blueprinter", "~> 0.25.1"
gem "versionist", "~> 2.0"
# To use local clone: bundle config local.odata_server ../odata_server
# To stop using local clone: bundle config --delete local.odata_server
gem "odata_server", github: "sassafrastech/odata_server", branch: "sassafras"

# Configuration
gem "config", "~> 2.2"
gem "configatron", "~> 4.5" # Deprecated, prefer `config` gem
gem "dotenv-rails", "~> 2.7"

# Tree modelling
gem "ancestry", "~> 3.0"
gem "closure_tree", github: "sassafrastech/closure_tree", tag: "v7.2.0-noReorder-fastInsert"

# Auto rank maintenance for sorted lists.
gem "acts_as_list"

# Caching
gem "actionpack-page_caching", "~> 1.1"
gem "bootsnap", "~> 1.4", require: false
gem "dalli", "~> 2.7"

# DB
gem "hairtrigger", "~> 0.2.20"
gem "immigrant", "~> 0.3.1" # foreign key maintenance
gem "pg", "~> 1.2"
gem "pg_search", "~> 2.1"
gem "postgres-copy", "~> 1.0"
gem "wisper", "~> 2.0"
gem "wisper-activerecord", "~> 1.0"

# Background/async
gem "delayed_job_active_record", "~> 4.1"
gem "parallel", "~> 1.19"
gem "whenever", "~> 1.0", require: false

# I18n
gem "i18n_country_select", "~> 1.2"
gem "i18n-country-translations", "~> 1.0"
gem "i18n-js", "~> 3.0"
gem "iso-639", "~> 0.3.5"
gem "rails-i18n", "~> 6.0"

# Analytics
gem "scout_apm", "~> 2.6"
gem "sentry-ruby", "~> 4.0"
gem "sentry-rails", "~> 4.0" # rubocop:disable Bundler/OrderedGems

# Force Sprockets to stay on v3 for now.
gem "sprockets", "~> 3"

# The below are used for building load test plans.
# Needed in prod because test plans are built on prod instances.
# Faker is also used in specs.
gem "faker", "~> 2.2"
gem "ruby-jmeter", "~> 3.1"

group :development do
  gem "binding_of_caller", "~> 0.8.0"
  gem "fix-db-schema-conflicts", "~> 3.0"
  gem "letter_opener", "~> 1.4"
  gem "listen", "~> 3.0"
  gem "rails-erd", "~> 1.4"
  gem "spring", "~> 1.3"
  gem "thin", "~> 1.7"

  # N+1 detection. Config is in environments/development.rb
  gem "bullet", "~> 6.1"

  # Great for debugging i18n paths (uncomment temporarily when needed).
  # gem "i18n-debug", "~> 1.1"

  # Profiling. Config is in environments/development.rb (uncomment temporarily when needed).
  # gem "rack-mini-profiler", "~> 2.0" # Automatically adds UI to the top left of all webpages.
  # gem "memory_profiler", "~> 0.9.14" # Append to URL: ?pp=profile-memory
  # gem "flamegraph", "~> 0.9.5" # Append to URL: ?pp=flamegraph
  # gem "stackprof", "~> 0.2.15"
end

group :development, :test do
  # Test framework
  gem "jasmine-rails", "~> 0.15.0" # Deprecated: Barely used.
  gem "rails-controller-testing", "~> 1.0" # Deprecated: Use request or feature specs instead.
  gem "rspec-collection_matchers", "~> 1.1"
  gem "rspec-rails", "~> 3.9"

  # Mocking/stubbing/factories
  gem "factory_bot_rails", "~> 4.11"
  gem "mocha", "~> 1.1"

  # Feature specs
  gem "capybara", "~> 3.30"
  gem "capybara-screenshot", "~> 1.0"
  gem "launchy", "~> 2.5" # For auto-opening capybara html file
  gem "puma", "~> 5.0"
  gem "selenium-webdriver", "~> 3.9"
  gem "webdrivers", "~> 4.0"

  # Debugging
  gem "pry", "~> 0.13"
  gem "pry-byebug", "~> 3.9"
  gem "pry-rails", "~> 0.3"

  # External request capture
  gem "vcr", "~> 6.0"
  gem "webmock", "~> 3.10"

  # gem "i18n-debug", "~> 1.1" # Great for debugging i18n paths. Uncomment temporarily when neeeded.

  # Misc
  gem "annotate", "~> 3.1"
  gem "assert_difference", "~> 1.0" # Deprecated: Barely used, convert usage to something else.
  gem "awesome_print", "~> 1.6"
  gem "database_cleaner", "~> 1.7"
  gem "db-query-matchers", "~> 0.10"
  gem "rubocop", "~> 0.91.0" # Hound supported versions: http://help.houndci.com/en/articles/2461415-supported-linters
  gem "rubocop-rails", "~> 2.8"
  gem "rubocop-rspec", "~> 1.44"
  gem "timecop", "~> 0.9.2"
end
