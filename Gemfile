# frozen_string_literal: true

source "http://rubygems.org"

gem "actionpack-page_caching", "~> 1.1.0"
gem "attribute_normalizer", "~> 1.2.0"
gem "daemons", "~> 1.2.1"
gem "dalli", "~> 2.7.4" # memcache
gem "delayed_job_active_record", "~> 4.1.3"
gem "descriptive_statistics", "~> 2.5.1", require: "descriptive_statistics/safe" # mean, median, etc.
gem "draper", "~> 3.0.1"
gem "exception_notification", "~> 4.2"
gem "fog-aws", "~> 3.3.0"
gem "friendly_id", "~> 5.1.0"
gem "hairtrigger", "~> 0.2.20"
gem "immigrant", "~> 0.3.1" # foreign key maintenance
gem "paperclip", "~> 6.0"
gem "pg", "~> 0.20"
gem "pg_search", "~> 2.1"
gem "phony", "~> 2.15.26"
gem "rack-attack", git: "https://github.com/sassafrastech/rack-attack.git"
gem "rails", "~> 5.2.2"
gem "rake", "~> 10.4.2"
gem "random_data", "~> 1.6.0" # Deprecated: Use Faker instead
gem "recaptcha", "~> 0.4.0", require: "recaptcha/rails"
gem "responders", "~> 2.4.0"
gem "rqrcode", "~> 0.10.1"
gem "term-ansicolor", "~> 1.3.0"
gem "mini_racer", "~> 0.2.4"
gem "thor", "0.19.1" # Newer versions produce command line argument errors. Remove constraint when fixed.
gem "twilio-ruby", "~> 4.1.0"
gem "whenever", "~> 0.9.4", require: false

# JS/CSS
gem "bootstrap-modal-rails", "~> 2.2.5"
gem "bootstrap", "~> 4.3.1"
gem "dropzonejs-rails", "~> 0.7.3"
gem "font-awesome-rails", "~> 4.7"
gem "jquery-fileupload-rails", "~> 0.4.5"
gem "jquery-rails", "~> 4.3.3"
gem "rails-backbone", git: "https://github.com/codebrew/backbone-rails.git"
gem "react-rails", "~> 2.4"
gem "sass-rails", "~> 5.0.7"
gem "select2-rails", "~> 4.0"
gem "spinjs-rails", "1.3"
gem "uglifier", "~> 2.7.1"
gem "webpacker", "~> 3.5"

# Authz and Authn
gem "activerecord-session_store", "~> 1.1.1"
gem "authlogic", "~> 4.4.2"
gem "cancancan", "~> 2.3.0"
gem "draper-cancancan", "~> 1.1"
gem "scrypt", "~> 3.0"

# Spreadsheets
gem "axlsx", "~> 2.1.1", git: "https://github.com/sassafrastech/axlsx.git", branch: "stable"
gem "axlsx_rails", "~> 0.5.0"
gem "roo", "~> 2.1.1"

# Pagination
gem "will_paginate", "~> 3.0.7"
gem "will_paginate-bootstrap4", "~> 0.2.2"

# Markdown
gem "bluecloth", "~> 2.2.0"
gem "rdiscount", "~> 2.1.8"
gem "reverse_markdown", "~> 1.0.3"

# API
gem "active_model_serializers", "~> 0.9.3"
gem "api-pagination", "~> 4.1.1"
gem "versionist", "~> 1.4.1"

# Configuration
gem "config", "~> 1.7"
gem "configatron", "~> 4.5.0" # Deprecated, prefer `config` gem

# Tree modelling
gem "ancestry", "~> 3.0.0"
gem "closure_tree", git: "https://github.com/sassafrastech/closure_tree.git"

# Auto rank maintenance for sorted lists.
gem "acts_as_list"

# I18n
gem "i18n-country-translations", "~> 1.2.3"
gem "i18n-js", "~> 3.0.0.rc13"
gem "i18n_country_select", "~> 1.1.7"
gem "iso-639", "~> 0.2.5"
gem "rails-i18n", "~> 5.1"

# The below are used for building load test plans.
# Needed in prod because test plans are built on prod instances.
# Faker is also used in specs.
gem "faker", "~> 1.6"
gem "ruby-jmeter", "~> 2.13.4"

group :development do
  gem "binding_of_caller", "~> 0.7.2"
  gem "bullet", "~> 5.9"
  gem "fix-db-schema-conflicts", "~> 3.0"
  gem "letter_opener", "~> 1.4.1"
  gem "rails-erd", "~> 1.4.0"
  gem "spring", "~> 1.3.3"
  gem "thin", "~> 1.7.0"
end

group :development, :test do
  # Test framework
  gem "jasmine-rails", "~> 0.10.7" # Deprecated: Barely used.
  gem "rails-controller-testing" # Deprecated: Use request or feature specs instead.
  gem "rspec-collection_matchers", "~> 1.1.3"
  gem "rspec-rails", "~> 3.7.2"

  # Mocking/stubbing/factories
  gem "factory_girl_rails", "~> 4.5.0"
  gem "mocha", "~> 1.1.0"

  # Feature specs
  gem "capybara", "~> 2.17"
  gem "capybara-screenshot", "~> 1.0.11"
  gem "launchy", "~> 2.4.3" # For auto-opening capybara html file
  gem "selenium-webdriver", "~> 3.9"

  # Debugging
  gem "pry", "~> 0.10"
  gem "pry-nav", "~> 0.2"
  gem "pry-rails", "~> 0.3"

  # gem "i18n-debug", "~> 1.1" # Great for debugging i18n paths. Uncomment temporarily when neeeded.

  # Misc
  gem "assert_difference", "~> 1.0.0" # Deprecated: Barely used, convert usage to something else.
  gem "awesome_print", "~> 1.6.1"
  gem "database_cleaner", "~> 1.7.0"
  gem "db-query-matchers", "~> 0.9"
  gem "timecop", "~> 0.7.3"
end
