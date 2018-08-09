source "http://rubygems.org"

gem "rails", "~> 5.1"

# Assets / Javascript
gem "sass-rails", "~> 5.0.7"
gem "uglifier", "~> 2.7.1"
gem "bootstrap-modal-rails", "~> 2.2.5"
gem "actionpack-page_caching", "~> 1.1.0"
gem "jquery-rails", "~> 4.3.3"
gem "jquery-fileupload-rails", "~> 0.4.5"
gem "rails-backbone", git: "https://github.com/codebrew/backbone-rails.git"
gem "dropzonejs-rails", "~> 0.7.3"
gem "phantomjs_polyfill-rails", "~> 1.0.0"

# Authentication
gem "activerecord-session_store", "~> 1.1.1"
gem "authlogic", "~> 3.7.0"
gem "scrypt", "~> 1.2.0"

# authorization
gem "cancancan", "~> 1.15.0"

# Fix for compatibility issue
gem "draper-cancancan", "~> 1.1"

# core
gem "rake", "~> 10.4.2"
gem "pg", "~> 0.20"
gem "configatron", "~> 4.5.0" # Deprecated, prefer `config` gem
gem "config", "~> 1.7"
gem "random_data", "~> 1.6.0"
gem "paperclip", "~> 6.0"
gem "term-ansicolor", "~> 1.3.0"
gem "therubyracer", "~> 0.12.2", platforms: :ruby
gem "draper", "~> 3.0.1"
gem "attribute_normalizer", "~> 1.2.0"
gem "responders", "~> 2.4.0"
gem "thor", "0.19.1" # Newer versions produce command line argument errors. Remove version constraint when fixed.
gem "friendly_id", "~> 5.1.0"

# pagination
gem "will_paginate", "~> 3.0.7"
gem "will_paginate-bootstrap", "~> 1.0.1"

# markdown support
gem "bluecloth", "~> 2.2.0"
gem "rdiscount", "~> 2.1.8"
gem "reverse_markdown", "~> 1.0.3"

# API
gem "versionist", "~> 1.4.1"
gem "active_model_serializers", "~> 0.9.3"
gem "api-pagination", "~> 4.1.1"

# Auto rank maintenance for sorted lists.
# We are using a fork due to incompatibility with acts_as_paranoid.
# See https://github.com/swanandp/acts_as_list/pull/286
gem "acts_as_list", git: "https://github.com/sassafrastech/acts_as_list.git"

# i18n
gem "i18n-js", "~> 3.0.0.rc13"
gem "rails-i18n", "~> 5.1"
gem "iso-639", "~> 0.2.5"
gem "i18n-country-translations", "~> 1.2.3"
gem "i18n_country_select", "~> 1.1.7"
# memcache
gem "dalli", "~> 2.7.4"

# foreign key maintenance
gem "immigrant", "~> 0.3.1"

# mean, median, etc.
gem "descriptive_statistics", "~> 2.5.1", require: "descriptive_statistics/safe"

# icons
gem "font-awesome-rails", "~> 4.7"

# Rich text editor
# Version 4.2.2 seems to have a bug with asset paths.
# See https://github.com/galetahub/ckeditor/issues/712#issuecomment-278740179
# So using latest master branch until that's fixed.
gem "ckeditor", git: "https://github.com/galetahub/ckeditor"

# Select box on steriods
gem "select2-rails", "~> 4.0"

# underscore templates
gem "ejs", "~> 1.1.1"

# background job support
gem "daemons", "~> 1.2.1"
gem "delayed_job_active_record", "~> 4.1.3"

# search
gem "pg_search"

# cron management
gem "whenever", "~> 0.9.4", require: false

# Bootstrap UI framework
gem "bootstrap-sass", "~> 3.3.4"

# spinner
gem "spinjs-rails", "1.3"

# tree data structure
gem "ancestry", "~> 3.0.0"

# Middleware for handling abusive requests
gem "rack-attack", git: "https://github.com/sassafrastech/rack-attack.git"

# reCAPTCHA support
gem "recaptcha", "~> 0.4.0", require: "recaptcha/rails"

# XLS support
gem "axlsx", "~> 2.1.1", git: "https://github.com/sassafrastech/axlsx.git", branch: "stable"
gem "axlsx_rails", "~> 0.5.0"
gem "roo", "~> 2.1.1"

# Twilio SMS integration
gem "twilio-ruby", "~> 4.1.0"

# Phone number normalization
gem "phony", "~> 2.15.26"

# Soft delete
gem "acts_as_paranoid", "~> 0.6.0"

# QR barcode
gem 'rqrcode', '~> 0.10.1'

# DB triggers
gem "hairtrigger", '~> 0.2.20'

# error emails
gem "exception_notification"

#react
gem "react-rails"
gem 'webpacker', '~> 3.5'

# Closure tree for answer heirarchy
gem "closure_tree", git: "https://github.com/smoyth/closure_tree", branch: "patch-1"

group :development do
  # generate diagrams with rake db:migrate
  gem "rails-erd", "~> 1.4.0"

  # query optimization
  gem "bullet", "~> 4.14.4"

  # development web server
  gem "thin", "~> 1.7.0"

  # speed up development mode
  gem "spring", "~> 1.3.3"

  # Better error pages
  gem "better_errors", "~> 2.1.1"
  gem "binding_of_caller", "~> 0.7.2"

  # misc
  gem "fix-db-schema-conflicts", "~> 2.0.0"
  gem "letter_opener", "~> 1.4.1"
end

group :development, :test do
  # test framework
  gem "jasmine-rails", "~> 0.10.7"
  gem "rspec-rails", "~> 3.7.2"
  gem "rspec-collection_matchers", "~> 1.1.3"
  gem "rails-controller-testing"

  # mocking/stubbing/factories
  gem "mocha", "~> 1.1.0"
  gem "faker", "~> 1.6"
  gem "factory_girl_rails", "~> 4.5.0"

  # acceptance tests
  gem "capybara", "~> 2.17"
  gem "capybara-screenshot", "~> 1.0.11"
  gem "selenium-webdriver", "~> 3.9"

  # cleans database for testing
  gem "database_cleaner", "~> 1.7.0"

   # sets time for testing
  gem "timecop", "~> 0.7.3"

  # for debugging/console, prints an object nicely
  gem "awesome_print", "~> 1.6.1"

  # test assertion
  gem "assert_difference", "~> 1.0.0"

  # auto-open capybara html file
  gem "launchy", "~> 2.4.3"

  # builds JMeter test plans
  gem "ruby-jmeter", "~> 2.13.4"

  # debugging
  gem "pry"
  gem "pry-nav"
  gem "pry-rails"
end
