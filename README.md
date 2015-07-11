Ridepilot
================

RidePilot is a paratransit trip scheduling application. 

RidePilot is originally a project of Ride Connection, a Portland-area community
transportation provider.  It is primarily written by hackers at
OpenPlans.

#More to add

Status
-------------
work in progress

- development: check [develop](https://github.com/camsys/ridepilot/tree/develop)

- latest stable: check [master](https://github.com/camsys/ridepilot/)

Dependencies
-------------

This application requires:

- Ruby 2.2.1
- Rails 4.2
- Postgresql 9.3+
- PostGIS 2.1+
- Imagemagick

Set up development environment
-------------

1. Install the required versions of Postgresql, PostGIS, and any other system packages required for your setup

2. Application setup
    - `bundle install`

3. Database setup

    - Copy `config/database.yml.example.pg` to `config/database.yml` and update the values.

    - `rake db:create`

    - To enable PostGIS, connect to your database with psql or pgAdmin, run:
  ```sql
  -- Enable PostGIS (includes raster)
  CREATE EXTENSION postgis;
  -- Enable Topology
  CREATE EXTENSION postgis_topology;
  -- fuzzy matching needed for Tiger
  CREATE EXTENSION fuzzystrmatch;
  ```
   - `rake db:migrate`
   - `rake translation_engine:install`
   - `rake db:seed`

4. Testing
    - `rake db:test:prepare`
    - `rake test`
    - `rspec`

5. Start application
    - Copy `config/app_config_template.yml` to `config/app_config.yml`.
    - `rails s`

License
-------
  TODO