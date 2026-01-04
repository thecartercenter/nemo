# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "~> 8.0.0"

# Force some gems to older versions to prevent error in prod:
# "You have already activated base64 0.1.1, but your Gemfile requires base64 0.2.0. Since base64 is a default gem, ..."
gem "stringio", "3.1.1"

# Misc
gem "attribute_normalizer", "~> 1.2"
gem "csv"
gem "daemons", "~> 1.2"
gem "descriptive_statistics", "~> 2.5", require: "descriptive_statistics/safe" # mean, median, etc.
gem "draper", "~> 4.0"
gem "eventmachine", "~> 1.2", platform: :ruby
gem "exception_notification", "~> 5.0", ">= 5.0.0"
gem "friendly_id", "~> 5.1"
gem "observer"
gem "phony", "~> 2.15"
gem "rack-attack", "~> 6.3"
gem "rake", "~> 13.0"
gem "random_data", "~> 1.6" # Deprecated: Use Faker instead
gem "recaptcha", "~> 3.4", require: "recaptcha/rails" # Small change in v4, we should upgrade eventually.
gem "responders", "~> 3.0"
gem "rqrcode", "~> 1.1"
gem "rubyzip", "~> 2.3", require: "zip" # Explicitly specify name (https://stackoverflow.com/a/32740666/763231)
gem "spreadsheet" # For XLSForm export
gem "term-ansicolor", "~> 1.3"
gem "terrapin", "~> 0.6.0"
gem "thor", "~> 1.4"
gem "twilio-ruby", "~> 7.2.0" # Does not use semver after v5, watch out!

# JS/CSS
gem "bootstrap", "~> 5.0"
# gem "bootstrap", "~> 4.3"  # Commented out - using Bootstrap 5.0
gem "clipboard-rails", "~> 1.7"
gem "dropzonejs-rails", "~> 0.8.5"
gem "flatpickr"
gem "font-awesome-rails", "~> 4.7"
gem "jquery-fileupload-rails", "~> 1.0"
gem "jquery-rails", "~> 4.3"
gem "popper_js", "~> 2.11"
gem "rails-backbone", git: "https://github.com/codebrew/backbone-rails.git"
gem "react-rails", "~> 3.0"
gem "sassc-rails", "~> 2.1"
gem "select2-rails", "~> 4.0"
gem "shakapacker", "~> 8.0", ">= 8.0.0"
gem "spinjs-rails", "~> 1.4.0" # Breaking changes in v1.4 (spin.js v2.0).
gem "uglifier", "~> 4.2"

# Authz and Authn
gem "authlogic", "~> 6.1"
gem "cancancan", "~> 3.1"
gem "draper-cancancan", "~> 1.1"
gem "scrypt", "~> 3.0"

# Pagination
gem "will_paginate", "~> 3.1"
gem "will_paginate-bootstrap4", "~> 0.2.2"

# Markdown
gem "bluecloth", "~> 2.2"
gem "rdiscount", "~> 2.1"
gem "reverse_markdown", "~> 2.0"

# Storage
gem "active_storage_validations", "~> 1.0.0"
gem "aws-sdk-s3", "~> 1.208", require: false
gem "azure-storage-blob", "~> 2.0", require: false
gem "image_processing", "~> 1.12"
gem "sys-filesystem", "~> 1.4"

# API
gem "api-pagination", "~> 4.1"
gem "blueprinter", "~> 0.25.1"
gem "versionist", "~> 2.0"
# To use local clone: bundle config local.odata_server ../odata_server
# To stop using local clone: bundle config --delete local.odata_server
gem "odata_server", github: "sassafrastech/odata_server", branch: "sassafras"

# Configuration
gem "dotenv-rails", "~> 3.0", ">= 3.0.0"

# Tree modelling
gem "ancestry", "~> 4.1"
# Fork: Performance improvements.
# https://github.com/sassafrastech/closure_tree/commits/master
gem "closure_tree", github: "sassafrastech/closure_tree", tag: "v7.4.0-noReorder-fastInsert"

# Auto rank maintenance for sorted lists.
gem "acts_as_list"

# Caching
gem "actionpack-page_caching", "~> 1.1"
gem "bootsnap", "~> 1.4", require: false
gem "dalli", "~> 3.2"

# DB
gem "hairtrigger", "~> 1.2"
gem "immigrant", "~> 0.3.1" # foreign key maintenance
gem "pg", "~> 1.5"
gem "pg_search", "~> 2.1"
gem "postgres-copy", "~> 1.0"
gem "wisper", "~> 2.0"
gem "wisper-activerecord", "~> 1.0"

# Background/async
gem "delayed_job_active_record", "~> 4.1"
gem "parallel", "~> 1.19"
gem "whenever", "~> 1.0", require: false

# I18n
gem "i18n-country-translations", "~> 1.0"
gem "i18n-js", "~> 3.0"
gem "iso-639", "~> 0.3.5"
gem "rails-i18n", "~> 8.0", ">= 8.0.0"

# Analytics
gem "scout_apm", "~> 5.0"
gem "sentry-ruby", "~> 5.0"
gem "sentry-rails", "~> 5.27", ">= 5.27.0" # rubocop:disable Bundler/OrderedGems

gem "sprockets"

# The below are used for building load test plans.
# Needed in prod because test plans are built on prod instances.
# Faker is also used in specs.
gem "faker", "~> 2.2"
gem "ruby-jmeter", "~> 3.1"

group :development do
  gem "binding_of_caller", "~> 1.0.0"
  gem "fix-db-schema-conflicts", "~> 3.0"
  gem "letter_opener", "~> 1.4"
  gem "listen", "~> 3.0"
  gem "rails-erd", "~> 1.6"

  # N+1 detection. Config is in environments/development.rb
  # gem "bullet", "~> 7.1" # Temporarily disabled - not compatible with Rails 8.0

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
  gem "rails-controller-testing", "~> 1.0" # Deprecated: Use request or feature specs instead.
  gem "rspec-collection_matchers", "~> 1.1"
  gem "rspec-rails", "~> 7.0", ">= 7.0.0"

  # Mocking/stubbing/factories
  gem "factory_bot_rails", "~> 5.0", ">= 5.0.0"
  gem "mocha", "~> 1.1"

  # system specs
  gem "capybara", "~> 3.30"
  gem "launchy", "~> 2.5" # For auto-opening capybara html file
  gem "puma", "~> 6.4"
  gem "selenium-webdriver", "~> 4.36", ">= 4.36.0"

  # External request capture
  gem "vcr", "~> 6.0"
  gem "webmock", "~> 3.10"

  # gem "i18n-debug", "~> 1.1" # Great for debugging i18n paths. Uncomment temporarily when neeeded.

  # Misc
  # gem "annotate", "~> 3.2" # Temporarily disabled - not compatible with Rails 8.0
  gem "assert_difference", "~> 1.0" # Deprecated: Barely used, convert usage to something else.
  gem "awesome_print", "~> 1.6"
  gem "brakeman"
  gem "bundler-audit"
  gem "db-query-matchers", "~> 0.10"
  gem "rubocop"

  gem "rubocop-rails", "~> 2.33", ">= 2.33.4"
  gem "rubocop-rake", "~> 0.6.0"
  gem "rubocop-rspec", "~> 2.0"
  gem "timecop", "0.9.6" # Timecop 0.9.8 breaks selenium (Selenium::WebDriver::Error::NoSuchWindowError).
end

group :test do
  gem "rspec-github", "~> 2.4", require: false
  gem "warning", "~> 1.3"
end
