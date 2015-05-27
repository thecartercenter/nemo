source 'http://rubygems.org'

gem 'rails', '4.2.1'

gem 'sass-rails', '~> 4.0.2'
gem 'uglifier', '>= 1.3.0'
gem 'bootstrap-modal-rails' # makes modals stackable

gem 'actionpack-page_caching'
gem 'activerecord-session_store'

gem 'authlogic', '3.4.5'
gem 'scrypt', '1.2'
gem 'rake'
gem 'mysql2', '>= 0.3.15' #was '~> 0.3.12b5' # beta version needed for sphinx
gem 'will_paginate'
gem 'will_paginate-bootstrap'
gem 'api-pagination'
gem 'configatron', '~> 4.2'
gem 'libxml-ruby'
gem 'rdiscount'
gem 'jquery-rails'
gem 'random_data'
gem 'versionist'                 # versioning the api
gem 'active_model_serializers'   # for making it easy to customize output for api

# Auto rank maintenance for sorted lists.
gem 'acts_as_list', :git => 'https://github.com/swanandp/acts_as_list', branch: 'master'

gem 'iso-639'
gem 'responders', '~> 2.0'

# authorization
gem 'cancancan', '~> 1.10'

# i18n for js
# temporary change to deal with rails 3.2.13 bug
gem 'i18n-js', :git => 'https://github.com/fnando/i18n-js.git', :branch => 'master'

# i18n locale data
gem 'rails-i18n', '~> 4.0.4'

# markdown support
gem 'bluecloth'

gem 'term-ansicolor'

# memcache
gem 'dalli'

# foreign key maintenance
gem 'immigrant'

# mean, median, etc.
gem 'descriptive_statistics', :require => 'descriptive_statistics/safe'

# underscore templates
gem 'ejs'

# search
gem 'thinking-sphinx', '~> 3.1.3'

# search: delayed deltas
gem 'daemons'
gem 'delayed_job_active_record'
gem 'ts-delayed-delta', '~> 2.0.2'

# cron management
gem 'whenever', :require => false

# Bootstrap UI framework
gem 'bootstrap-sass', '~> 3.3.3'

# spinner
gem 'spinjs-rails', '1.3'

# tree data structure
gem 'ancestry', '~> 2.0'

gem 'rails-backbone', github: 'codebrew/backbone-rails'

# Middleware for handling abusive requests
gem 'rack-attack', github: 'sassafrastech/rack-attack'

# reCAPTCHA support
gem "recaptcha", :require => "recaptcha/rails"

# XLS support
gem 'roo'

gem 'therubyracer', platforms: :ruby

# Converting HTML to markdown for CSV export
gem 'reverse_markdown'

# Twilio SMS integration
gem 'twilio-ruby', ' ~> 4.1'

group :development do
  gem 'rails-erd'                     # generate with rake db:migrate
  gem 'capistrano', '~> 2.15.4'       # deployment
  gem 'bullet'                        # query optimization
  gem 'thin'                          # development web server
  gem 'rails-dev-tweaks', '~> 1.1'    # speed up development mode
  gem 'spring'
end

group :development, :test do
  gem 'factory_girl_rails', '~> 4.0'
  gem 'jasmine-rails', '~> 0.10.7'   # test framework
  gem 'rspec-rails', '~> 3.0'        # test framework
  gem 'mocha'                        # mocking/stubbing
  gem 'capybara'                     # acceptance tests
  gem 'selenium-webdriver'
  gem 'poltergeist', '~> 1.6'
  gem 'database_cleaner'             # cleans database for testing
  gem 'timecop'                      # sets time for testing
  gem 'awesome_print'                # for debugging/console, prints an object nicely
  gem 'assert_difference'            # test assertion
  gem 'launchy'                      # auto-open capybara html file
end
