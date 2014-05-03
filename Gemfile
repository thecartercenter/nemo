source 'http://rubygems.org'

gem 'rails', '~> 3.2'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'uglifier', '>= 1.0.3'
  # makes modals stackable
  gem 'bootstrap-modal-rails'
end

gem 'authlogic', '3.3.0'
gem 'rake'
gem 'mysql2', '>= 0.3.15' #was '~> 0.3.12b5' # beta version needed for sphinx
gem 'will_paginate'
gem 'will_paginate-bootstrap'
gem 'configatron'
gem 'libxml-ruby'
gem 'rdiscount'
gem 'jquery-rails'
gem 'random_data'
gem 'versionist'        # versioning the api

# Ckeditor integration gem for rails http://ckeditor.com/
gem 'ckeditor'

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
gem 'thinking-sphinx', '~> 3.0.2'

gem 'pry' # better debugger

# cron management
gem 'whenever', :require => false

# Bootstrap UI framework
gem 'bootstrap-sass', '~> 3.0.3.0'

# spinner
gem 'spinjs-rails'

group :development do
  gem 'rails-erd'                     # generat with:  DIAGRAM=true rake db:migrate
  gem 'capistrano', '~> 2.15.4'       # deployment
  gem 'bullet'                        # query optimization
end

group :development, :test do
  gem 'factory_girl_rails', '~> 4.0'
  gem 'rspec-rails'                  # test framework
  gem 'pry'                          # better debugger
  gem 'mocha'                        # mocking/stubbing
  gem 'capybara'                     # acceptance tests
  gem 'database_cleaner'             # cleans database for testing
  gem 'timecop'                      # sets time for testing
end
