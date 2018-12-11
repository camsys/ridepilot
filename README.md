Ridepilot Verson 3
================

The purpose of this project is to implement a Computer Aided Scheduling and Dispatch (CASD) software system to meet the needs of small scale human service transportation agencies. 

Status
-------------
work in progress

- development: check [develop](https://github.com/camsys/ridepilot/tree/develop)

- latest stable: check [master](https://github.com/camsys/ridepilot/tree/master)

- RidePilot CAD/AVL engine: check [CAD/AVL](https://github.com/camsys/ridepilot_cad_avl)

- RideAVL driver mobile app: check [RideAVL](https://github.com/camsys/rideavl)

Dependencies
-------------

This application requires:

- Ruby 2.4.5
- Rails 5.2
- Postgresql 9.3+
- PostGIS 2.1+
- Imagemagick
- Redis

Set up development environment (native, see below for docker setup)
-------------

1. Install the required versions of Postgresql, PostGIS, and any other system packages required for your setup

2. Application setup
    - `bundle install`
    - Copy `config/application.example.yml` to `config/application.yml` and update the values.

3. Database setup
    - Copy `config/database.yml.example.pg` to `config/database.yml` and update the values for specific environment (at least __development__ and __test__).

    - `rails db:setup`
    - 'rails sql:create_gps_locations_partition'

4. Testing
    - set up test database if not yet
      - make sure `config/database.yml` has the configurations for __test__ environment
    - update schema and locales
      - `rails db:test:prepare`
    - `rspec`

5. Start application
    - `rails s`

Set up docker-based development environment
-------------

1. Install [docker and docker-compose](https://www.docker.com/products/docker-desktop)

2. Configuration
    - Copy `config/database.yml.docker` to `config/database.yml`
    - Copy `config/application.example.yml` to `config/application.yml` and update the values.

3. Build
    - Under RidePilot root directory, run `docker-compose build` to build images
    - Setup local database: `docker-compose run app rails db:setup`
    - Might need to run `docker-compose run app rails ridepilot:load_locales` to add translations

4. Start and stop app
    - `docker-compose up` to start
    - open `localhost` 
    - `CTRL + C` to stop


License
-------
  The RidePilot platform source code is released as open-source software under the GNU Affero General Public License v3 (http://www.gnu.org/licenses/agpl-3.0.en.html) license.