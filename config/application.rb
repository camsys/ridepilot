require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ridepilot
  class ActiveRecordOverrideRailtie < Rails::Railtie
    initializer "active_record.initialize_database.override" do |app|

      ActiveSupport.on_load(:active_record) do
        if url = ENV['DATABASE_URL']
          ActiveRecord::Base.connection_pool.disconnect!
          parsed_url = URI.parse(url)
          config =  {
            adapter:             'postgis',
            host:                parsed_url.host,
            encoding:            'unicode',
            database:            parsed_url.path.split("/")[-1],
            port:                parsed_url.port,
            username:            parsed_url.user,
            password:            parsed_url.password
          }
          establish_connection(config)
        end
      end
    end
  end
  
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Mountain Time (US & Canada)'

    config.i18n.enforce_available_locales = false
    config.i18n.default_locale = :en

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.view_specs false
      g.helper_specs false
      
      # It is suggested to leave these all enabled
      # g.request_specs false
      # g.routing_specs false
      # g.controller_specs false
      # g.model_specs false
    end
    
    # Use Redis as the cache_store if it's available
    if ENV["REDISCLOUD_URL"]
      config.cache_store = :redis_store, ENV["REDISCLOUD_URL"], { expires_in: 90.minutes }
    end
  end
end
