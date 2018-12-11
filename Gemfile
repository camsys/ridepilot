source 'https://rubygems.org'

ruby '2.4.5'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

### DEFAULT RAILS GEMS ####################

gem 'rails', '~> 5.2.1'
# Use SCSS for stylesheets
gem 'sass-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer',  platforms: :ruby
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
#gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.0'
# A set of Rails responders to dry up your application
gem 'responders', '~> 2.0'
# Use PostgreSQL as db for activerecord
gem 'pg'

### UI ####################################

# view partial template
gem 'haml'
# bootstrap
gem 'bootstrap-sass'
# needed for trip address picker
gem 'twitter-typeahead-rails', github: 'camsys/twitter-typeahead-rails'
gem 'handlebars_assets'
# jquery autocomplete
gem 'rails-jquery-autocomplete'
# view pagination
gem 'will_paginate'
# html datatables
gem 'jquery-datatables-rails'
# font-awesome icons
gem "font-awesome-rails"
# overcome IE9 4096 per stylesheet limit
gem 'css_splitter'
# Form helper for accepts_nested_attributes_for
gem 'nested_form'
# styling
gem 'bootstrap-kaminari-views'
# momentjs for datetime parsing
gem 'momentjs-rails'
# phone number validation and display
gem 'phony_rails'
# Printing
gem 'wicked_pdf'
# In-line editing
gem 'bootstrap-editable-rails'

### USER AUTH ##############################

gem 'cancancan'
gem 'devise'
gem 'devise_account_expireable'
gem 'devise_security_extension', github: 'camsys/devise_security_extension'
#gem 'devise_security_extension', path: '~/devise_security_extension'

### API ##############################
# Rack Middleware for handling Cross-Origin Resource Sharing (CORS), which makes cross-origin AJAX possible.
gem 'rack-cors', :require => 'rack/cors'
# Token authentication
gem 'simple_token_authentication', '~> 1.0'
# API serializer
#gem 'fast_jsonapi', github: 'Netflix/fast_jsonapi', branch: 'dev'

### GEOSPATIAL ##############################

gem 'rgeo'
gem "rgeo-proj4"
gem 'activerecord-postgis-adapter'

### FILE UPLOAD #############################

gem 'paperclip'
gem 'fog-aws'
gem 'remotipart' # allows remote multipart (file upload) forms
gem 'aws-sdk-s3', '~> 1'

### CAMSYS ENGINES ###########################

# reporting engine
gem 'reporting', github: 'camsys/reporting', branch: 'rails_5'
#gem 'reporting', path: '~/reporting'
gem 'translation_engine', github: 'camsys/translation_engine', branch: 'rails_5'
#gem 'translation_engine', path: '~/translation_engine'
gem 'ridepilot_cad_avl', github: 'camsys/ridepilot_cad_avl', branch: 'v0.0.11'
#gem 'ridepilot_cad_avl', path: '~/ridepilot_cad_avl'

### OTHERS ##################################

# Manage app-specific cron tasks using a Ruby DSL, see config/schedule.rb
gem 'whenever', :require => false
# RADAR current version is 0.13.0, but schedule_atts requires > 0.7.0 
gem 'ice_cube', '~> 0.6.8'
# Date and time validation plugin for ActiveModel and Rails
gem 'jc-validates_timeliness'
# Adds the ability to normalize attributes cleanly with code blocks and predefined normalizers
gem 'attribute_normalizer'
# For change tracking and auditing
gem 'paper_trail'
# ENV var management
gem 'figaro'
# soft-delete
gem "paranoia"
# logging activities for Tracker Action Log
gem 'public_activity' 
# Manage application-level settings
gem 'rails-settings-cached'
# background workder
gem 'sidekiq'
# Use redis as the cache_store for Rails
gem 'redis-rails'
# Excel
gem 'rubyXL'
# Data migration
gem 'data_migrate'

group :production do
  gem 'exception_notification'
end

group :integration, :qa, :production do 
  gem 'rails_12factor'
  gem 'unicorn'
  gem 'rack-timeout'
  gem 'wkhtmltopdf-binary'
end

group :test, :development do
  gem 'byebug'
  gem 'rspec-rails'
  gem 'rails-controller-testing'
  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'database_cleaner'
  gem 'faker'
  gem 'timecop'
end

group :development do
  gem 'puma', '~> 3.7'
  # preview mail in dev
  gem "letter_opener"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem "spring-commands-rspec"
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'web-console', '~> 2.0'
end

group :test do 
  gem 'launchy'
  gem 'selenium-webdriver'
end

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc'
end
