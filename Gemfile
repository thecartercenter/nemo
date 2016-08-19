source "http://rubygems.org"

gem "rails", "4.2.5"

# Assets / Javascript
gem "sass-rails", "~> 4.0.2"
gem "uglifier", ">= 1.3.0"
gem "bootstrap-modal-rails"
gem "actionpack-page_caching"
gem "jquery-rails"
gem "jquery-fileupload-rails"
gem "rails-backbone", github: "codebrew/backbone-rails"
gem "dropzonejs-rails"
gem "phantomjs_polyfill-rails"

# Authentication
gem "activerecord-session_store"
gem "authlogic", "3.4.5"
gem "scrypt", "1.2"

# authorization
gem "cancancan", "~> 1.10"

# core
gem "rake"
gem "mysql2", ">= 0.3.15"
gem "configatron", "~> 4.2"
gem "random_data"
gem "paperclip"
gem "term-ansicolor"
gem "therubyracer", platforms: :ruby
gem "draper", "~> 2.1"
gem "attribute_normalizer"
gem "responders"

# pagination
gem "will_paginate"
gem "will_paginate-bootstrap"

# markdown support
gem "bluecloth"
gem "rdiscount"
gem "reverse_markdown"

# API
gem "versionist"
gem "active_model_serializers"
gem "api-pagination"

# Auto rank maintenance for sorted lists.
gem "acts_as_list", github: "swanandp/acts_as_list", branch: "master"

# i18n
gem "i18n-js", "~> 3.0.0.rc11"
gem "rails-i18n", "~> 4.0.4"
gem "iso-639"

# memcache
gem "dalli"

# foreign key maintenance
gem "immigrant"

# mean, median, etc.
gem "descriptive_statistics", require: "descriptive_statistics/safe"

# underscore templates
gem "ejs"

# background job support
gem "daemons"
gem "delayed_job_active_record"

# search
gem "thinking-sphinx", "~> 3.1.3"
gem "ts-delayed-delta", "~> 2.0.2"

# cron management
gem "whenever", require: false

# Bootstrap UI framework
gem "bootstrap-sass", "~> 3.3.3"

# spinner
gem "spinjs-rails", "1.3"

# tree data structure
gem "ancestry", "~> 2.0"

# Middleware for handling abusive requests
gem "rack-attack", github: "sassafrastech/rack-attack"

# reCAPTCHA support
gem "recaptcha", require: "recaptcha/rails"

# XLS support
gem "axlsx", "~> 2.1.0.pre"
gem "axlsx_rails"
gem "roo", "~> 2.1.1"

# Twilio SMS integration
gem "twilio-ruby", " ~> 4.1"

# Phone number normalization
gem "phony"

group :development do
  # generate diagrams with rake db:migrate
  gem "rails-erd"

  # deployment
  gem "capistrano", "~> 2.15.4"

  # query optimization
  gem "bullet"

  # development web server
  gem "thin"

  # speed up development mode
  gem "rails-dev-tweaks", "~> 1.1"
  gem "spring"

  # Better error pages
  gem "better_errors"
  gem "binding_of_caller"

  # misc
  gem "apiary"
  gem "fix-db-schema-conflicts"
end

group :development, :test do
  # test framework
  gem "jasmine-rails", "~> 0.10.7"
  gem "rspec-rails", "~> 3.0"
  gem "rspec-collection_matchers"

  # mocking/stubbing/factories
  gem "mocha"
  gem "faker"
  gem "factory_girl_rails", "~> 4.0"

  # acceptance tests
  gem "capybara"
  gem "capybara-screenshot"
  gem "selenium-webdriver"
  gem "poltergeist", "~> 1.6"

  # cleans database for testing
  gem "database_cleaner"

   # sets time for testing
  gem "timecop"

  # for debugging/console, prints an object nicely
  gem "awesome_print"

  # test assertion
  gem "assert_difference"

  # auto-open capybara html file
  gem "launchy"

  # builds JMeter test plans
  gem "ruby-jmeter", "~> 2.13.4"

  # removes "get assets" from logs
  gem "quiet_assets"
end
