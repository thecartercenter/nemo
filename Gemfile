source 'http://rubygems.org'

gem 'rails', '~> 3.2'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'uglifier', '>= 1.0.3'
  # makes modals stackable
  gem 'bootstrap-modal-rails'
end

gem 'authlogic', '3.3.0'
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

gem 'iso-639'

# authorization
gem 'cancan'

# i18n for js
# temporary change to deal with rails 3.2.13 bug
gem 'i18n-js', :git => 'https://github.com/fnando/i18n-js.git', :branch => 'master'

# i18n locale data
gem 'rails-i18n'

# markdown support
gem 'bluecloth'

gem 'term-ansicolor'

# memcache
gem 'dalli'

# foreign key maintenance
gem 'foreigner'
gem 'immigrant'

# mean, median, etc.
gem 'descriptive_statistics', :require => 'descriptive_statistics/safe'

# underscore templates
gem 'ejs'

# search
gem 'thinking-sphinx', '~> 3.0'

# cron management
gem 'whenever', :require => false

# Bootstrap UI framework
gem 'bootstrap-sass', '~> 3.0.3.0'

# spinner
gem 'spinjs-rails'

# tree data structure
gem 'ancestry', '~> 2.0'

gem 'rails-backbone', github: 'codebrew/backbone-rails'

# XLS support
gem 'roo'

# Converting HTML to markdown for CSV export
gem 'reverse_markdown'

group :development do
  gem 'rails-erd'                     # generat with:  DIAGRAM=true rake db:migrate
  gem 'capistrano', '~> 2.15.4'       # deployment
  gem 'bullet'                        # query optimization
  gem 'thin'                          # development web server
  gem 'rails-dev-tweaks', '~> 1.1'    # speed up development mode
end

group :development, :test do
  gem 'factory_girl_rails', '~> 4.0'
  gem 'jasmine-rails'                # test framework
  gem 'rspec-rails', '~> 3.0'        # test framework
  gem 'rspec-its'
  gem 'rspec-activemodel-mocks'
  gem 'mocha'                        # mocking/stubbing
  gem 'capybara'                     # acceptance tests
  gem 'capybara-webkit'              # for testing js
  gem 'selenium-webdriver'
  gem 'poltergeist'
  gem 'database_cleaner'             # cleans database for testing
  gem 'timecop'                      # sets time for testing
  gem 'awesome_print'                # for debugging/console, prints an object nicely
  gem 'assert_difference'            # test assertion
  gem 'debugger'
  gem 'debugger-xml'
  gem 'launchy'                      # auto-open capybara html file
end
