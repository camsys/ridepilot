Ridepilot Verson 2
================

The purpose of this project is to implement a Computer Aided Scheduling and Dispatch (CASD) software system to meet the needs of small scale human service transportation agencies. RidePilot, an open source, web-based scheduling, reporting, and dispatch application developed by Ride Connection in Portland Oregon, was identified to fill this need. Utah Transit Authority is participating in a joint software development project ([Ridepilot Version 2](https://ridepilot.camsys-apps.com)) to build upon RidePilot’s current functionality ([Ridepilot Version 1](https://github.com/rideconnection/ridepilot)) and expand it to meet the needs of human service agencies in the Wasatch Front region. 

Status
-------------
work in progress

- development: check [develop](https://github.com/camsys/ridepilot/tree/develop)

- latest stable: check [master](https://github.com/camsys/ridepilot/tree/master)

- Ridepilot Version 1 branch: check [ridepilot\_v1](https://github.com/camsys/ridepilot/tree/ridepilot_v1)

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

    - Copy `config/database.yml.example.pg` to `config/database.yml` and update the values for specific environment (at least __development__ and __test__).

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
   - `rake translation_engine:install`
   - `rake db:migrate`
   - `rake db:seed`

4. Testing
    - set up test database if not yet
      - make sure `config/database.yml` has the configurations for __test__ environment
    - update schema and locales
      - `rake db:test:prepare`
    - `rspec`

5. Start application
    - Copy `config/application.example.yml` to `config/application.yml` and update the values.
    - Copy `config/app_config_template.yml` to `config/app_config.yml`. # might be deprecated
    - `rails s`

License
-------
  Dual-licensed under the [MIT](http://opensource.org/licenses/MIT]) and [GPL v3](https://www.gnu.org/licenses/gpl-3.0.txt) licenses.