# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150803224056) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "postgis_topology"
  enable_extension "fuzzystrmatch"

  create_table "address_upload_flags", force: true do |t|
    t.boolean  "is_loading",          default: false
    t.integer  "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "last_upload_summary"
  end

  add_index "address_upload_flags", ["provider_id"], :name => "index_address_upload_flags_on_provider_id"

  create_table "addresses", force: true do |t|
    t.string   "name"
    t.string   "building_name"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.boolean  "in_district",                                                               default: false
    t.integer  "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                                                              default: 0
    t.string   "phone_number"
    t.boolean  "inactive",                                                                  default: false
    t.string   "trip_purpose_old"
    t.spatial  "the_geom",         limit: {:srid=>4326, :type=>"point", :geographic=>true}
    t.integer  "trip_purpose_id"
    t.text     "notes"
  end

  add_index "addresses", ["provider_id"], :name => "index_addresses_on_provider_id"
  add_index "addresses", ["the_geom"], :name => "index_addresses_on_the_geom", :spatial => true
  add_index "addresses", ["trip_purpose_id"], :name => "index_addresses_on_trip_purpose_id"

  create_table "customers", force: true do |t|
    t.string   "first_name"
    t.string   "middle_initial"
    t.string   "last_name"
    t.string   "phone_number_1"
    t.string   "phone_number_2"
    t.integer  "address_id"
    t.string   "email"
    t.date     "activated_date"
    t.date     "inactivated_date"
    t.string   "inactivated_reason"
    t.date     "birth_date"
    t.integer  "mobility_id"
    t.text     "mobility_notes"
    t.string   "ethnicity"
    t.text     "emergency_contact_notes"
    t.text     "private_notes"
    t.text     "public_notes"
    t.integer  "provider_id"
    t.boolean  "group",                     default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",              default: 0
    t.boolean  "medicaid_eligible"
    t.string   "prime_number"
    t.integer  "default_funding_source_id"
    t.boolean  "ada_eligible"
    t.string   "service_level_old"
    t.integer  "service_level_id"
  end

  add_index "customers", ["address_id"], :name => "index_customers_on_address_id"
  add_index "customers", ["default_funding_source_id"], :name => "index_customers_on_default_funding_source_id"
  add_index "customers", ["mobility_id"], :name => "index_customers_on_mobility_id"
  add_index "customers", ["provider_id"], :name => "index_customers_on_provider_id"
  add_index "customers", ["service_level_id"], :name => "index_customers_on_service_level_id"

  create_table "customers_providers", id: false, force: true do |t|
    t.integer "provider_id"
    t.integer "customer_id"
  end

  add_index "customers_providers", ["customer_id", "provider_id"], :name => "index_customers_providers_on_customer_id_and_provider_id"
  add_index "customers_providers", ["customer_id"], :name => "index_customers_providers_on_customer_id"
  add_index "customers_providers", ["provider_id"], :name => "index_customers_providers_on_provider_id"

  create_table "device_pool_drivers", force: true do |t|
    t.string   "status"
    t.float    "lat"
    t.float    "lng"
    t.integer  "device_pool_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "driver_id"
    t.datetime "posted_at"
    t.integer  "vehicle_id"
  end

  add_index "device_pool_drivers", ["device_pool_id"], :name => "index_device_pool_drivers_on_device_pool_id"
  add_index "device_pool_drivers", ["driver_id"], :name => "index_device_pool_drivers_on_driver_id"
  add_index "device_pool_drivers", ["vehicle_id"], :name => "index_device_pool_drivers_on_vehicle_id"

  create_table "device_pools", force: true do |t|
    t.integer  "provider_id"
    t.string   "name"
    t.string   "color"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "device_pools", ["provider_id"], :name => "index_device_pools_on_provider_id"

  create_table "documents", force: true do |t|
    t.integer  "documentable_id"
    t.string   "documentable_type"
    t.string   "description"
    t.string   "document_file_name"
    t.string   "document_content_type"
    t.integer  "document_file_size"
    t.datetime "document_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "documents", ["documentable_id", "documentable_type"], :name => "index_documents_on_documentable_id_and_documentable_type"

  create_table "driver_compliances", force: true do |t|
    t.integer  "driver_id"
    t.string   "event"
    t.text     "notes"
    t.date     "due_date"
    t.date     "compliance_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "driver_compliances", ["driver_id"], :name => "index_driver_compliances_on_driver_id"

  create_table "driver_histories", force: true do |t|
    t.integer  "driver_id"
    t.string   "event"
    t.text     "notes"
    t.date     "event_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "driver_histories", ["driver_id"], :name => "index_driver_histories_on_driver_id"

  create_table "drivers", force: true do |t|
    t.boolean  "active"
    t.boolean  "paid"
    t.integer  "provider_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version", default: 0
    t.integer  "user_id"
    t.string   "email"
  end

  add_index "drivers", ["provider_id"], :name => "index_drivers_on_provider_id"
  add_index "drivers", ["user_id"], :name => "index_drivers_on_user_id"

  create_table "funding_source_visibilities", force: true do |t|
    t.integer "funding_source_id"
    t.integer "provider_id"
  end

  add_index "funding_source_visibilities", ["funding_source_id"], :name => "index_funding_source_visibilities_on_funding_source_id"
  add_index "funding_source_visibilities", ["provider_id"], :name => "index_funding_source_visibilities_on_provider_id"

  create_table "funding_sources", force: true do |t|
    t.string "name"
  end

  create_table "locales", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_tables", force: true do |t|
    t.string   "caption"
    t.string   "name"
    t.string   "value_column_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "add_value_allowed",    default: true
    t.boolean  "edit_value_allowed",   default: true
    t.boolean  "delete_value_allowed", default: true
  end

  create_table "mobilities", force: true do |t|
    t.string   "name"
    t.datetime "deleted_at"
  end

  add_index "mobilities", ["deleted_at"], :name => "index_mobilities_on_deleted_at"

  create_table "monthlies", force: true do |t|
    t.date     "start_date"
    t.integer  "volunteer_escort_hours"
    t.integer  "volunteer_admin_hours"
    t.integer  "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",           default: 0
    t.integer  "funding_source_id"
  end

  add_index "monthlies", ["funding_source_id"], :name => "index_monthlies_on_funding_source_id"
  add_index "monthlies", ["provider_id"], :name => "index_monthlies_on_provider_id"

  create_table "old_passwords", force: true do |t|
    t.string   "encrypted_password",       null: false
    t.string   "password_archivable_type", null: false
    t.integer  "password_archivable_id",   null: false
    t.datetime "created_at"
  end

  add_index "old_passwords", ["password_archivable_type", "password_archivable_id"], :name => "index_password_archivable"

  create_table "operating_hours", force: true do |t|
    t.integer  "driver_id"
    t.integer  "day_of_week"
    t.time     "start_time"
    t.time     "end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "operating_hours", ["driver_id"], :name => "index_operating_hours_on_driver_id"

  create_table "provider_ethnicities", force: true do |t|
    t.integer  "provider_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "provider_ethnicities", ["provider_id"], :name => "index_provider_ethnicities_on_provider_id"

  create_table "providers", force: true do |t|
    t.string   "name"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.boolean  "dispatch"
    t.boolean  "scheduling"
    t.integer  "viewport_zoom"
    t.boolean  "allow_trip_entry_from_runs_page"
    t.decimal  "oaa3b_per_ride_reimbursement_rate",                                                                        precision: 8, scale: 2
    t.decimal  "ride_connection_per_ride_reimbursement_rate",                                                              precision: 8, scale: 2
    t.decimal  "trimet_per_ride_reimbursement_rate",                                                                       precision: 8, scale: 2
    t.decimal  "stf_van_per_ride_reimbursement_rate",                                                                      precision: 8, scale: 2
    t.decimal  "stf_taxi_per_ride_administrative_fee",                                                                     precision: 8, scale: 2
    t.decimal  "stf_taxi_per_ride_ambulatory_load_fee",                                                                    precision: 8, scale: 2
    t.decimal  "stf_taxi_per_ride_wheelchair_load_fee",                                                                    precision: 8, scale: 2
    t.decimal  "stf_taxi_per_mile_ambulatory_reimbursement_rate",                                                          precision: 8, scale: 2
    t.decimal  "stf_taxi_per_mile_wheelchair_reimbursement_rate",                                                          precision: 8, scale: 2
    t.spatial  "region_nw_corner",                                limit: {:srid=>4326, :type=>"point", :geographic=>true}
    t.spatial  "region_se_corner",                                limit: {:srid=>4326, :type=>"point", :geographic=>true}
    t.spatial  "viewport_center",                                 limit: {:srid=>4326, :type=>"point", :geographic=>true}
  end

  create_table "regions", force: true do |t|
    t.string  "name"
    t.spatial "the_geom", limit: {:srid=>4326, :type=>"polygon", :geographic=>true}
  end

  add_index "regions", ["the_geom"], :name => "index_regions_on_the_geom", :spatial => true

  create_table "repeating_trips", force: true do |t|
    t.text     "schedule_yaml"
    t.integer  "provider_id"
    t.integer  "customer_id"
    t.datetime "pickup_time"
    t.datetime "appointment_time"
    t.integer  "guest_count",        default: 0
    t.integer  "attendant_count",    default: 0
    t.integer  "group_size",         default: 0
    t.integer  "pickup_address_id"
    t.integer  "dropoff_address_id"
    t.integer  "mobility_id"
    t.integer  "funding_source_id"
    t.string   "trip_purpose_old"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",       default: 0
    t.boolean  "round_trip"
    t.integer  "driver_id"
    t.integer  "vehicle_id"
    t.boolean  "cab",                default: false
    t.boolean  "customer_informed"
    t.integer  "trip_purpose_id"
  end

  add_index "repeating_trips", ["customer_id"], :name => "index_repeating_trips_on_customer_id"
  add_index "repeating_trips", ["driver_id"], :name => "index_repeating_trips_on_driver_id"
  add_index "repeating_trips", ["dropoff_address_id"], :name => "index_repeating_trips_on_dropoff_address_id"
  add_index "repeating_trips", ["funding_source_id"], :name => "index_repeating_trips_on_funding_source_id"
  add_index "repeating_trips", ["mobility_id"], :name => "index_repeating_trips_on_mobility_id"
  add_index "repeating_trips", ["pickup_address_id"], :name => "index_repeating_trips_on_pickup_address_id"
  add_index "repeating_trips", ["provider_id"], :name => "index_repeating_trips_on_provider_id"
  add_index "repeating_trips", ["trip_purpose_id"], :name => "index_repeating_trips_on_trip_purpose_id"
  add_index "repeating_trips", ["vehicle_id"], :name => "index_repeating_trips_on_vehicle_id"

  create_table "roles", force: true do |t|
    t.integer "user_id"
    t.integer "provider_id"
    t.integer "level"
  end

  add_index "roles", ["provider_id"], :name => "index_roles_on_provider_id"
  add_index "roles", ["user_id"], :name => "index_roles_on_user_id"

  create_table "runs", force: true do |t|
    t.string   "name"
    t.date     "date"
    t.integer  "start_odometer"
    t.integer  "end_odometer"
    t.datetime "scheduled_start_time"
    t.datetime "scheduled_end_time"
    t.integer  "unpaid_driver_break_time"
    t.integer  "vehicle_id"
    t.integer  "driver_id"
    t.boolean  "paid"
    t.boolean  "complete"
    t.integer  "provider_id"
    t.datetime "actual_start_time"
    t.datetime "actual_end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",             default: 0
  end

  add_index "runs", ["driver_id"], :name => "index_runs_on_driver_id"
  add_index "runs", ["provider_id", "date"], :name => "index_runs_on_provider_id_and_date"
  add_index "runs", ["provider_id", "scheduled_start_time"], :name => "index_runs_on_provider_id_and_scheduled_start_time"
  add_index "runs", ["vehicle_id"], :name => "index_runs_on_vehicle_id"

  create_table "service_levels", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "service_levels", ["deleted_at"], :name => "index_service_levels_on_deleted_at"

  create_table "settings", force: true do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["thing_type", "thing_id", "var"], :name => "index_settings_on_thing_type_and_thing_id_and_var", :unique => true

  create_table "translation_keys", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translations", force: true do |t|
    t.integer  "locale_id"
    t.integer  "translation_key_id"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "travel_time_estimates", id: false, force: true do |t|
    t.integer "from_address_id"
    t.integer "to_address_id"
    t.integer "seconds"
  end

  create_table "trip_purposes", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "trip_purposes", ["deleted_at"], :name => "index_trip_purposes_on_deleted_at"

  create_table "trip_results", force: true do |t|
    t.string   "code"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "trip_results", ["deleted_at"], :name => "index_trip_results_on_deleted_at"

  create_table "trips", force: true do |t|
    t.integer  "run_id"
    t.integer  "customer_id"
    t.datetime "pickup_time"
    t.datetime "appointment_time"
    t.integer  "guest_count",                                 default: 0
    t.integer  "attendant_count",                             default: 0
    t.integer  "group_size",                                  default: 0
    t.integer  "pickup_address_id"
    t.integer  "dropoff_address_id"
    t.integer  "mobility_id"
    t.integer  "funding_source_id"
    t.string   "trip_purpose_old"
    t.string   "trip_result_old",                             default: ""
    t.text     "notes"
    t.decimal  "donation",           precision: 10, scale: 2, default: 0.0
    t.integer  "provider_id"
    t.datetime "called_back_at"
    t.boolean  "customer_informed",                           default: false
    t.integer  "repeating_trip_id"
    t.boolean  "cab",                                         default: false
    t.boolean  "cab_notified",                                default: false
    t.text     "guests"
    t.integer  "called_back_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                                default: 0
    t.boolean  "round_trip"
    t.boolean  "medicaid_eligible"
    t.integer  "mileage"
    t.string   "service_level_old"
    t.integer  "trip_purpose_id"
    t.integer  "trip_result_id"
    t.integer  "service_level_id"
  end

  add_index "trips", ["called_back_by_id"], :name => "index_trips_on_called_back_by_id"
  add_index "trips", ["customer_id"], :name => "index_trips_on_customer_id"
  add_index "trips", ["dropoff_address_id"], :name => "index_trips_on_dropoff_address_id"
  add_index "trips", ["funding_source_id"], :name => "index_trips_on_funding_source_id"
  add_index "trips", ["mobility_id"], :name => "index_trips_on_mobility_id"
  add_index "trips", ["pickup_address_id"], :name => "index_trips_on_pickup_address_id"
  add_index "trips", ["provider_id", "appointment_time"], :name => "index_trips_on_provider_id_and_appointment_time"
  add_index "trips", ["provider_id", "pickup_time"], :name => "index_trips_on_provider_id_and_pickup_time"
  add_index "trips", ["repeating_trip_id"], :name => "index_trips_on_repeating_trip_id"
  add_index "trips", ["run_id"], :name => "index_trips_on_run_id"
  add_index "trips", ["service_level_id"], :name => "index_trips_on_service_level_id"
  add_index "trips", ["trip_purpose_id"], :name => "index_trips_on_trip_purpose_id"
  add_index "trips", ["trip_result_id"], :name => "index_trips_on_trip_result_id"

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "password_salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "current_provider_id"
    t.string   "unconfirmed_email"
    t.datetime "reset_password_sent_at"
    t.datetime "password_changed_at"
    t.datetime "expires_at"
    t.string   "inactivation_reason"
  end

  add_index "users", ["current_provider_id"], :name => "index_users_on_current_provider_id"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["password_changed_at"], :name => "index_users_on_password_changed_at"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "vehicle_maintenance_events", force: true do |t|
    t.integer  "vehicle_id",                                              null: false
    t.integer  "provider_id",                                             null: false
    t.boolean  "reimbursable"
    t.date     "service_date"
    t.date     "invoice_date"
    t.text     "services_performed"
    t.decimal  "odometer",           precision: 10, scale: 1
    t.string   "vendor_name"
    t.string   "invoice_number"
    t.decimal  "invoice_amount",     precision: 10, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                                default: 0
  end

  add_index "vehicle_maintenance_events", ["provider_id"], :name => "index_vehicle_maintenance_events_on_provider_id"
  add_index "vehicle_maintenance_events", ["vehicle_id"], :name => "index_vehicle_maintenance_events_on_vehicle_id"

  create_table "vehicles", force: true do |t|
    t.string   "name"
    t.integer  "year"
    t.string   "make"
    t.string   "model"
    t.string   "license_plate"
    t.string   "vin"
    t.string   "garaged_location"
    t.integer  "provider_id"
    t.boolean  "active",            default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",      default: 0
    t.integer  "default_driver_id"
    t.boolean  "reportable"
  end

  add_index "vehicles", ["default_driver_id"], :name => "index_vehicles_on_default_driver_id"
  add_index "vehicles", ["provider_id"], :name => "index_vehicles_on_provider_id"

  create_table "versions", force: true do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

end
