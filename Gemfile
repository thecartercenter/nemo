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

gem 'authlogic'
gem 'rake'
gem 'mysql2', '0.3.12b5' # beta version needed for sphinx
gem 'will_paginate'
gem 'will_paginate-bootstrap'
gem 'configatron'
gem 'libxml-ruby'
gem 'rdiscount'
gem 'jquery-rails'
gem 'random_data'

# Ckeditor integration gem for rails http://ckeditor.com/
gem "ckeditor"

# building factories for testing -- stupid and offensive name but it's a good gem :(
gem "factory_girl_rails", "~> 4.0"

gem "iso-639"

# helps simulate time changes when testing
gem 'timecop'

# authorization
gem 'cancan'

# i18n for js
# temporary change to deal with rails 3.2.13 bug
gem 'i18n-js', :git => 'https://github.com/fnando/i18n-js.git', :branch => 'master'

# i18n locale data
gem 'rails-i18n'

# for deployment
gem 'capistrano', :group => :development

# markdown support
gem 'bluecloth'

# query optimization
gem "bullet", :group => "development"
gem 'term-ansicolor'

# memcache
gem 'dalli'

# foreign key maintenance
gem 'foreigner'
gem 'immigrant'

# diagraming
gem "rails-erd"

# mean, median, etc.
gem 'descriptive_statistics', :require => 'descriptive_statistics/safe'

# underscore templates
gem 'ejs'

# search
gem 'thinking-sphinx', '~> 3.0.2'

# cleaning db for testing
gem 'database_cleaner', :group => [:development, :test]

# Test framework
gem 'rspec-rails', :group => [:development, :test]

# Acceptance test framework
gem 'capybara', :group => [:development, :test]

# cron management
gem 'whenever', :require => false

# Bootstrap UI framework
gem 'bootstrap-sass', '~> 3.0.3.0'

# mocking/stubbing
gem 'mocha', :group => [:development, :test], :require => false

# spinner
gem 'spinjs-rails'