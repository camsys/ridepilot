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

ActiveRecord::Schema.define(version: 2019_03_02_211128) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "postgis_topology"
  enable_extension "uuid-ossp"

  create_table "activities", id: :serial, force: :cascade do |t|
    t.integer "trackable_id"
    t.string "trackable_type", limit: 255
    t.integer "owner_id"
    t.string "owner_type", limit: 255
    t.string "key", limit: 255
    t.text "parameters"
    t.integer "recipient_id"
    t.string "recipient_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type"
    t.index ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type"
    t.index ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type"
  end

  create_table "ada_questions", id: :serial, force: :cascade do |t|
    t.integer "provider_id"
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider_id"], name: "index_ada_questions_on_provider_id"
  end

  create_table "address_groups", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "address_upload_flags", id: :serial, force: :cascade do |t|
    t.boolean "is_loading", default: false
    t.integer "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "last_upload_summary"
    t.index ["provider_id"], name: "index_address_upload_flags_on_provider_id"
  end

  create_table "addresses", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "building_name", limit: 255
    t.string "address", limit: 255
    t.string "city", limit: 255
    t.string "state", limit: 255
    t.string "zip", limit: 255
    t.boolean "in_district"
    t.integer "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lock_version", default: 0
    t.string "phone_number", limit: 255
    t.boolean "inactive", default: false
    t.string "trip_purpose_old", limit: 255
    t.geography "the_geom", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.integer "trip_purpose_id"
    t.text "notes"
    t.datetime "deleted_at"
    t.integer "customer_id"
    t.boolean "is_driver_associated", default: false
    t.boolean "is_user_associated"
    t.string "type", limit: 255
    t.integer "address_group_id"
    t.index ["address_group_id"], name: "index_addresses_on_address_group_id"
    t.index ["customer_id"], name: "index_addresses_on_customer_id"
    t.index ["deleted_at"], name: "index_addresses_on_deleted_at"
    t.index ["provider_id"], name: "index_addresses_on_provider_id"
    t.index ["the_geom"], name: "index_addresses_on_the_geom", using: :gist
    t.index ["trip_purpose_id"], name: "index_addresses_on_trip_purpose_id"
  end

  create_table "addresses_customers_old", id: :serial, force: :cascade do |t|
    t.integer "customer_id"
    t.integer "address_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["address_id"], name: "index_addresses_customers_old_on_address_id"
    t.index ["customer_id"], name: "index_addresses_customers_old_on_customer_id"
  end

  create_table "booking_users", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string "url", limit: 255
    t.uuid "token", default: -> { "uuid_generate_v4()" }
    t.index ["user_id"], name: "index_booking_users_on_user_id"
  end

  create_table "boolean_lookup", id: :serial, force: :cascade do |t|
    t.string "name", limit: 16
    t.string "note", limit: 16
  end

  create_table "capacities", id: :serial, force: :cascade do |t|
    t.integer "capacity_type_id"
    t.integer "capacity"
    t.integer "host_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type", limit: 255
    t.index ["capacity_type_id"], name: "index_capacities_on_capacity_type_id"
    t.index ["host_id"], name: "index_capacities_on_host_id"
  end

  create_table "capacity_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "provider_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider_id"], name: "index_capacity_types_on_provider_id"
  end

  create_table "chat_read_receipts", force: :cascade do |t|
    t.bigint "run_id"
    t.bigint "message_id"
    t.integer "read_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_chat_read_receipts_on_message_id"
    t.index ["run_id"], name: "index_chat_read_receipts_on_run_id"
  end

  create_table "custom_reports", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "redirect_to_results", default: false
    t.string "title", limit: 255
    t.string "version", limit: 255
  end

  create_table "customer_ada_questions", id: :serial, force: :cascade do |t|
    t.integer "customer_id"
    t.integer "ada_question_id"
    t.boolean "answer"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["ada_question_id"], name: "index_customer_ada_questions_on_ada_question_id"
    t.index ["customer_id"], name: "index_customer_ada_questions_on_customer_id"
  end

  create_table "customer_address_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "code", limit: 255
    t.datetime "deleted_at"
  end

  create_table "customer_eligibilities", id: :serial, force: :cascade do |t|
    t.integer "customer_id"
    t.integer "eligibility_id"
    t.text "ineligible_reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "eligible"
    t.index ["customer_id"], name: "index_customer_eligibilities_on_customer_id"
    t.index ["eligibility_id"], name: "index_customer_eligibilities_on_eligibility_id"
  end

  create_table "customers", id: :serial, force: :cascade do |t|
    t.string "first_name", limit: 255
    t.string "middle_initial", limit: 255
    t.string "last_name", limit: 255
    t.string "phone_number_1", limit: 255
    t.string "phone_number_2", limit: 255
    t.integer "address_id"
    t.string "email", limit: 255
    t.date "activated_date"
    t.date "inactivated_date"
    t.string "inactivated_reason", limit: 255
    t.date "birth_date"
    t.integer "mobility_id"
    t.text "mobility_notes"
    t.string "ethnicity", limit: 255
    t.text "emergency_contact_notes"
    t.text "private_notes"
    t.text "public_notes"
    t.integer "provider_id"
    t.boolean "group", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lock_version", default: 0
    t.boolean "medicaid_eligible"
    t.string "prime_number", limit: 255
    t.integer "default_funding_source_id"
    t.boolean "ada_eligible"
    t.string "service_level_old", limit: 255
    t.integer "service_level_id"
    t.boolean "is_elderly"
    t.string "gender", limit: 255
    t.datetime "deleted_at"
    t.text "message"
    t.string "token", limit: 255
    t.boolean "active"
    t.date "inactivated_start_date"
    t.date "inactivated_end_date"
    t.text "active_status_changed_reason"
    t.text "comments"
    t.text "ada_ineligible_reason"
    t.string "code", limit: 255
    t.integer "passenger_load_min"
    t.integer "passenger_unload_min"
    t.index ["address_id"], name: "index_customers_on_address_id"
    t.index ["default_funding_source_id"], name: "index_customers_on_default_funding_source_id"
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
    t.index ["mobility_id"], name: "index_customers_on_mobility_id"
    t.index ["provider_id"], name: "index_customers_on_provider_id"
    t.index ["service_level_id"], name: "index_customers_on_service_level_id"
  end

  create_table "customers_providers", id: false, force: :cascade do |t|
    t.integer "provider_id"
    t.integer "customer_id"
    t.index ["customer_id", "provider_id"], name: "index_customers_providers_on_customer_id_and_provider_id"
    t.index ["customer_id"], name: "index_customers_providers_on_customer_id"
    t.index ["provider_id"], name: "index_customers_providers_on_provider_id"
  end

  create_table "daily_operating_hours", id: :serial, force: :cascade do |t|
    t.date "date"
    t.time "start_time"
    t.time "end_time"
    t.integer "operatable_id"
    t.string "operatable_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_all_day", default: false
    t.boolean "is_unavailable", default: false
  end

  create_table "data_migrations", id: false, force: :cascade do |t|
    t.string "version", null: false
    t.index ["version"], name: "unique_data_migrations", unique: true
  end

  create_table "device_pool_drivers", id: :serial, force: :cascade do |t|
    t.string "status", limit: 255
    t.float "lat"
    t.float "lng"
    t.integer "device_pool_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "driver_id"
    t.datetime "posted_at"
    t.integer "vehicle_id"
    t.index ["device_pool_id"], name: "index_device_pool_drivers_on_device_pool_id"
    t.index ["driver_id"], name: "index_device_pool_drivers_on_driver_id"
    t.index ["vehicle_id"], name: "index_device_pool_drivers_on_vehicle_id"
  end

  create_table "device_pools", id: :serial, force: :cascade do |t|
    t.integer "provider_id"
    t.string "name", limit: 255
    t.string "color", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_device_pools_on_deleted_at"
    t.index ["provider_id"], name: "index_device_pools_on_provider_id"
  end

  create_table "document_associations", id: :serial, force: :cascade do |t|
    t.integer "document_id"
    t.integer "associable_id"
    t.string "associable_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["associable_id", "associable_type"], name: "index_document_associations_on_associable_id_and_associable_typ"
    t.index ["document_id", "associable_id", "associable_type"], name: "index_document_associations_document_id_associable"
    t.index ["document_id"], name: "index_document_associations_on_document_id"
  end

  create_table "documents", id: :serial, force: :cascade do |t|
    t.integer "documentable_id"
    t.string "documentable_type", limit: 255
    t.string "description", limit: 255
    t.string "document_file_name", limit: 255
    t.string "document_content_type", limit: 255
    t.integer "document_file_size"
    t.datetime "document_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["documentable_id", "documentable_type"], name: "index_documents_on_documentable_id_and_documentable_type"
  end

  create_table "donations", id: :serial, force: :cascade do |t|
    t.datetime "date"
    t.float "amount"
    t.text "notes"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "customer_id"
    t.integer "user_id"
    t.integer "trip_id"
    t.index ["customer_id"], name: "index_donations_on_customer_id"
    t.index ["trip_id"], name: "index_donations_on_trip_id"
    t.index ["user_id"], name: "index_donations_on_user_id"
  end

  create_table "driver_compliances", id: :serial, force: :cascade do |t|
    t.integer "driver_id"
    t.string "event", limit: 255
    t.text "notes"
    t.date "due_date"
    t.date "compliance_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "recurring_driver_compliance_id"
    t.boolean "legal"
    t.integer "driver_requirement_template_id"
    t.index ["driver_id"], name: "index_driver_compliances_on_driver_id"
    t.index ["driver_requirement_template_id"], name: "index_driver_compliances_on_driver_requirement_template_id"
    t.index ["recurring_driver_compliance_id"], name: "index_driver_compliances_on_recurring_driver_compliance_id"
  end

  create_table "driver_histories", id: :serial, force: :cascade do |t|
    t.integer "driver_id"
    t.string "event", limit: 255
    t.text "notes"
    t.date "event_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["driver_id"], name: "index_driver_histories_on_driver_id"
  end

  create_table "driver_requirement_templates", id: :serial, force: :cascade do |t|
    t.integer "provider_id"
    t.string "name", limit: 255
    t.boolean "legal"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "reoccuring"
    t.datetime "deleted_at"
    t.index ["provider_id"], name: "index_driver_requirement_templates_on_provider_id"
  end

  create_table "drivers", id: :serial, force: :cascade do |t|
    t.boolean "active"
    t.boolean "paid"
    t.integer "provider_id"
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lock_version", default: 0
    t.integer "user_id"
    t.string "email", limit: 255
    t.integer "address_id"
    t.datetime "deleted_at"
    t.string "phone_number", limit: 255
    t.integer "alt_address_id"
    t.string "alt_phone_number", limit: 255
    t.date "inactivated_start_date"
    t.date "inactivated_end_date"
    t.text "active_status_changed_reason"
    t.index ["address_id"], name: "index_drivers_on_address_id"
    t.index ["alt_address_id"], name: "index_drivers_on_alt_address_id"
    t.index ["deleted_at"], name: "index_drivers_on_deleted_at"
    t.index ["provider_id"], name: "index_drivers_on_provider_id"
    t.index ["user_id"], name: "index_drivers_on_user_id"
  end

  create_table "eligibilities", id: :serial, force: :cascade do |t|
    t.string "code", limit: 255, null: false
    t.string "description", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "emergency_contacts", id: :serial, force: :cascade do |t|
    t.integer "geocoded_address_id"
    t.integer "driver_id"
    t.string "name", limit: 255
    t.string "phone_number", limit: 255
    t.string "relationship", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "ethnicities", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_ethnicities_on_deleted_at"
  end

  create_table "fares", force: :cascade do |t|
    t.integer "fare_type"
    t.boolean "pre_trip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "field_configs", id: :serial, force: :cascade do |t|
    t.integer "provider_id", null: false
    t.string "table_name", limit: 255, null: false
    t.string "field_name", limit: 255, null: false
    t.boolean "visible", default: true
    t.boolean "required", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider_id"], name: "index_field_configs_on_provider_id"
  end

  create_table "funding_authorization_numbers", id: :serial, force: :cascade do |t|
    t.integer "funding_source_id"
    t.integer "customer_id"
    t.string "number", limit: 255
    t.text "contact_info"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["customer_id"], name: "index_funding_authorization_numbers_on_customer_id"
    t.index ["funding_source_id"], name: "index_funding_authorization_numbers_on_funding_source_id"
  end

  create_table "funding_source_visibilities", id: :serial, force: :cascade do |t|
    t.integer "funding_source_id"
    t.integer "provider_id"
    t.index ["funding_source_id"], name: "index_funding_source_visibilities_on_funding_source_id"
    t.index ["provider_id"], name: "index_funding_source_visibilities_on_provider_id"
  end

  create_table "funding_sources", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "deleted_at"
    t.integer "provider_id"
    t.boolean "ntd_reportable"
    t.index ["deleted_at"], name: "index_funding_sources_on_deleted_at"
    t.index ["provider_id"], name: "index_funding_sources_on_provider_id"
  end

  create_table "gps_location_partitions", force: :cascade do |t|
    t.integer "provider_id"
    t.integer "year"
    t.integer "month"
    t.string "table_name"
  end

  create_table "gps_locations", force: :cascade do |t|
    t.float "latitude"
    t.float "longitude"
    t.float "bearing"
    t.float "speed"
    t.datetime "log_time"
    t.integer "accuracy"
    t.bigint "provider_id"
    t.bigint "run_id"
    t.integer "itinerary_id"
    t.index ["provider_id", "log_time"], name: "index_gps_locations_on_provider_id_and_log_time"
    t.index ["provider_id"], name: "index_gps_locations_on_provider_id"
    t.index ["run_id"], name: "index_gps_locations_on_run_id"
  end

  create_table "hidden_lookup_table_values", id: :serial, force: :cascade do |t|
    t.integer "provider_id"
    t.string "table_name", limit: 255
    t.integer "value_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider_id"], name: "index_hidden_lookup_table_values_on_provider_id"
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.integer "imageable_id"
    t.string "imageable_type", limit: 255
    t.string "image_file_name", limit: 255
    t.string "image_content_type", limit: 255
    t.integer "image_file_size"
    t.datetime "image_updated_at"
    t.index ["imageable_id", "imageable_type"], name: "index_images_on_imageable_id_and_imageable_type"
  end

  create_table "itineraries", id: :serial, force: :cascade do |t|
    t.datetime "time"
    t.datetime "eta"
    t.integer "travel_time"
    t.integer "address_id"
    t.integer "run_id"
    t.integer "trip_id"
    t.integer "leg_flag"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "depart_time"
    t.integer "status_code"
    t.datetime "departure_time"
    t.datetime "arrival_time"
    t.datetime "finish_time"
    t.datetime "deleted_at"
    t.index ["address_id"], name: "index_itineraries_on_address_id"
    t.index ["run_id"], name: "index_itineraries_on_run_id"
    t.index ["trip_id"], name: "index_itineraries_on_trip_id"
  end

  create_table "locales", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lookup_tables", id: :serial, force: :cascade do |t|
    t.string "caption", limit: 255
    t.string "name", limit: 255
    t.string "value_column_name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "add_value_allowed", default: true
    t.boolean "edit_value_allowed", default: true
    t.boolean "delete_value_allowed", default: true
    t.string "model_name_str", limit: 255
    t.string "code_column_name", limit: 255
    t.string "description_column_name", limit: 255
  end

  create_table "message_templates", force: :cascade do |t|
    t.text "message"
    t.bigint "provider_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_message_templates_on_provider_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "provider_id"
    t.string "type"
    t.text "body"
    t.integer "sender_id"
    t.integer "reader_id"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "driver_id"
    t.bigint "run_id"
    t.index ["driver_id"], name: "index_messages_on_driver_id"
    t.index ["provider_id"], name: "index_messages_on_provider_id"
    t.index ["reader_id"], name: "index_messages_on_reader_id"
    t.index ["run_id"], name: "index_messages_on_run_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "mobilities", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_mobilities_on_deleted_at"
  end

  create_table "monthlies", id: :serial, force: :cascade do |t|
    t.date "start_date"
    t.integer "volunteer_escort_hours"
    t.integer "volunteer_admin_hours"
    t.integer "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lock_version", default: 0
    t.integer "funding_source_id"
    t.index ["funding_source_id"], name: "index_monthlies_on_funding_source_id"
    t.index ["provider_id"], name: "index_monthlies_on_provider_id"
  end

  create_table "old_passwords", id: :serial, force: :cascade do |t|
    t.string "encrypted_password", limit: 255, null: false
    t.string "password_archivable_type", limit: 255, null: false
    t.integer "password_archivable_id", null: false
    t.datetime "created_at"
    t.index ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable"
  end

  create_table "operating_hours", id: :serial, force: :cascade do |t|
    t.integer "operatable_id"
    t.integer "day_of_week"
    t.time "start_time"
    t.time "end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "operatable_type", limit: 255
    t.boolean "is_all_day", default: false
    t.boolean "is_unavailable", default: false
    t.index ["operatable_id", "operatable_type"], name: "index_operating_hours_on_operatable_id_and_operatable_type"
    t.index ["operatable_id"], name: "index_operating_hours_on_operatable_id"
  end

  create_table "planned_leaves", id: :serial, force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.text "reason"
    t.integer "leavable_id"
    t.string "leavable_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["leavable_id", "leavable_type"], name: "index_planned_leaves_on_leavable_id_and_leavable_type"
  end

  create_table "provider_lookup_tables", id: :serial, force: :cascade do |t|
    t.string "caption", limit: 255
    t.string "name", limit: 255
    t.string "value_column_name", limit: 255
    t.string "model_name_str", limit: 255
    t.string "code_column_name", limit: 255
    t.string "description_column_name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "provider_reports", id: :serial, force: :cascade do |t|
    t.integer "provider_id"
    t.integer "custom_report_id"
    t.boolean "inactive"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["custom_report_id"], name: "index_provider_reports_on_custom_report_id"
    t.index ["provider_id"], name: "index_provider_reports_on_provider_id"
  end

  create_table "providers", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "logo_file_name", limit: 255
    t.string "logo_content_type", limit: 255
    t.integer "logo_file_size"
    t.datetime "logo_updated_at"
    t.boolean "dispatch"
    t.boolean "scheduling"
    t.integer "viewport_zoom"
    t.boolean "allow_trip_entry_from_runs_page"
    t.decimal "oaa3b_per_ride_reimbursement_rate", precision: 8, scale: 2
    t.decimal "ride_connection_per_ride_reimbursement_rate", precision: 8, scale: 2
    t.decimal "trimet_per_ride_reimbursement_rate", precision: 8, scale: 2
    t.decimal "stf_van_per_ride_reimbursement_rate", precision: 8, scale: 2
    t.decimal "stf_taxi_per_ride_administrative_fee", precision: 8, scale: 2
    t.decimal "stf_taxi_per_ride_ambulatory_load_fee", precision: 8, scale: 2
    t.decimal "stf_taxi_per_ride_wheelchair_load_fee", precision: 8, scale: 2
    t.decimal "stf_taxi_per_mile_ambulatory_reimbursement_rate", precision: 8, scale: 2
    t.decimal "stf_taxi_per_mile_wheelchair_reimbursement_rate", precision: 8, scale: 2
    t.geography "region_nw_corner", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.geography "region_se_corner", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.geography "viewport_center", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.text "fields_required_for_run_completion"
    t.datetime "deleted_at"
    t.integer "min_trip_time_gap_in_mins", default: 30
    t.boolean "customer_nonsharable", default: false
    t.datetime "inactivated_date"
    t.string "inactivated_reason", limit: 255
    t.integer "advance_day_scheduling"
    t.boolean "cab_enabled"
    t.integer "eligible_age"
    t.boolean "run_tracking"
    t.string "phone_number", limit: 255
    t.string "alt_phone_number", limit: 255
    t.string "url", limit: 255
    t.string "primary_contact_name", limit: 255
    t.string "primary_contact_phone_number", limit: 255
    t.string "primary_contact_email", limit: 255
    t.integer "business_address_id"
    t.integer "mailing_address_id"
    t.string "admin_name", limit: 255
    t.integer "driver_availability_min_hour", default: 6
    t.integer "driver_availability_max_hour", default: 22
    t.integer "driver_availability_interval_min", default: 30
    t.integer "driver_availability_days_ahead", default: 30
    t.integer "passenger_load_min"
    t.integer "passenger_unload_min"
    t.integer "very_early_arrival_threshold_min"
    t.integer "early_arrival_threshold_min"
    t.integer "late_arrival_threshold_min"
    t.integer "very_late_arrival_threshold_min"
    t.bigint "fare_id"
    t.index ["business_address_id"], name: "index_providers_on_business_address_id"
    t.index ["deleted_at"], name: "index_providers_on_deleted_at"
    t.index ["fare_id"], name: "index_providers_on_fare_id"
    t.index ["mailing_address_id"], name: "index_providers_on_mailing_address_id"
  end

  create_table "public_itineraries", force: :cascade do |t|
    t.bigint "run_id"
    t.bigint "itinerary_id"
    t.datetime "eta"
    t.integer "sequence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["itinerary_id"], name: "index_public_itineraries_on_itinerary_id"
    t.index ["run_id"], name: "index_public_itineraries_on_run_id"
  end

  create_table "recurring_driver_compliances", id: :serial, force: :cascade do |t|
    t.integer "provider_id"
    t.string "event_name", limit: 255
    t.text "event_notes"
    t.string "recurrence_schedule", limit: 255
    t.integer "recurrence_frequency"
    t.text "recurrence_notes"
    t.date "start_date"
    t.string "future_start_rule", limit: 255
    t.string "future_start_schedule", limit: 255
    t.integer "future_start_frequency"
    t.boolean "compliance_based_scheduling", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider_id"], name: "index_recurring_driver_compliances_on_provider_id"
  end

  create_table "recurring_vehicle_maintenance_compliances", id: :serial, force: :cascade do |t|
    t.integer "provider_id"
    t.string "event_name", limit: 255
    t.text "event_notes"
    t.string "recurrence_type", limit: 255
    t.string "recurrence_schedule", limit: 255
    t.integer "recurrence_frequency"
    t.integer "recurrence_mileage"
    t.text "recurrence_notes"
    t.date "start_date"
    t.string "future_start_rule", limit: 255
    t.string "future_start_schedule", limit: 255
    t.integer "future_start_frequency"
    t.boolean "compliance_based_scheduling", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider_id"], name: "index_recurring_vehicle_maintenance_compliances_on_provider_id"
  end

  create_table "regions", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.geography "the_geom", limit: {:srid=>4326, :type=>"st_polygon", :geographic=>true}
    t.datetime "deleted_at"
    t.boolean "is_primary"
    t.index ["deleted_at"], name: "index_regions_on_deleted_at"
    t.index ["the_geom"], name: "index_regions_on_the_geom", using: :gist
  end

  create_table "repeating_itineraries", id: :serial, force: :cascade do |t|
    t.datetime "time"
    t.datetime "eta"
    t.integer "travel_time"
    t.integer "address_id"
    t.integer "repeating_run_id"
    t.integer "repeating_trip_id"
    t.integer "leg_flag"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "wday"
    t.datetime "depart_time"
    t.index ["address_id"], name: "index_repeating_itineraries_on_address_id"
    t.index ["repeating_run_id"], name: "index_repeating_itineraries_on_repeating_run_id"
    t.index ["repeating_trip_id"], name: "index_repeating_itineraries_on_repeating_trip_id"
  end

  create_table "repeating_run_manifest_orders", id: :serial, force: :cascade do |t|
    t.integer "repeating_run_id"
    t.integer "wday"
    t.text "manifest_order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["repeating_run_id"], name: "index_repeating_run_manifest_orders_on_repeating_run_id"
  end

  create_table "repeating_runs", id: :serial, force: :cascade do |t|
    t.text "schedule_yaml"
    t.string "name", limit: 255
    t.date "date"
    t.datetime "scheduled_start_time"
    t.datetime "scheduled_end_time"
    t.integer "vehicle_id"
    t.integer "driver_id"
    t.boolean "paid"
    t.integer "provider_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "start_date"
    t.date "end_date"
    t.string "comments", limit: 255
    t.integer "unpaid_driver_break_time"
    t.date "scheduled_through"
    t.text "manifest_order"
    t.string "scheduled_start_time_string", limit: 255
    t.string "scheduled_end_time_string", limit: 255
    t.index ["driver_id"], name: "index_repeating_runs_on_driver_id"
    t.index ["provider_id"], name: "index_repeating_runs_on_provider_id"
    t.index ["vehicle_id"], name: "index_repeating_runs_on_vehicle_id"
  end

  create_table "repeating_trips", id: :serial, force: :cascade do |t|
    t.text "schedule_yaml"
    t.integer "provider_id"
    t.integer "customer_id"
    t.datetime "pickup_time"
    t.datetime "appointment_time"
    t.integer "guest_count", default: 0
    t.integer "attendant_count", default: 0
    t.integer "group_size", default: 0
    t.integer "pickup_address_id"
    t.integer "dropoff_address_id"
    t.integer "mobility_id"
    t.integer "funding_source_id"
    t.string "trip_purpose_old", limit: 255
    t.text "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lock_version", default: 0
    t.integer "driver_id"
    t.integer "vehicle_id"
    t.boolean "cab", default: false
    t.boolean "customer_informed"
    t.integer "trip_purpose_id"
    t.string "direction", limit: 255, default: "outbound"
    t.integer "service_level_id"
    t.boolean "medicaid_eligible"
    t.integer "mobility_device_accommodations"
    t.date "start_date"
    t.date "end_date"
    t.string "comments", limit: 255
    t.integer "repeating_run_id"
    t.date "scheduled_through"
    t.string "pickup_address_notes", limit: 255
    t.string "dropoff_address_notes", limit: 255
    t.integer "customer_space_count"
    t.integer "service_animal_space_count"
    t.integer "passenger_load_min"
    t.integer "passenger_unload_min"
    t.boolean "early_pickup_allowed"
    t.integer "linking_trip_id"
    t.index ["customer_id"], name: "index_repeating_trips_on_customer_id"
    t.index ["driver_id"], name: "index_repeating_trips_on_driver_id"
    t.index ["dropoff_address_id"], name: "index_repeating_trips_on_dropoff_address_id"
    t.index ["funding_source_id"], name: "index_repeating_trips_on_funding_source_id"
    t.index ["linking_trip_id"], name: "index_repeating_trips_on_linking_trip_id"
    t.index ["mobility_id"], name: "index_repeating_trips_on_mobility_id"
    t.index ["pickup_address_id"], name: "index_repeating_trips_on_pickup_address_id"
    t.index ["provider_id"], name: "index_repeating_trips_on_provider_id"
    t.index ["service_level_id"], name: "index_repeating_trips_on_service_level_id"
    t.index ["trip_purpose_id"], name: "index_repeating_trips_on_trip_purpose_id"
    t.index ["vehicle_id"], name: "index_repeating_trips_on_vehicle_id"
  end

  create_table "reporting_filter_fields", id: :serial, force: :cascade do |t|
    t.integer "filter_group_id", null: false
    t.integer "filter_type_id", null: false
    t.integer "lookup_table_id"
    t.string "name", limit: 255, null: false
    t.string "title", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sort_order", default: 1, null: false
    t.string "value_type", limit: 255
    t.index ["filter_group_id"], name: "index_reporting_filter_fields_on_filter_group_id"
    t.index ["filter_type_id"], name: "index_reporting_filter_fields_on_filter_type_id"
    t.index ["lookup_table_id"], name: "index_reporting_filter_fields_on_lookup_table_id"
  end

  create_table "reporting_filter_groups", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reporting_filter_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reporting_lookup_tables", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "display_field_name", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "id_field_name", limit: 255, default: "id", null: false
    t.string "data_access_type", limit: 255
  end

  create_table "reporting_output_fields", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "title", limit: 255
    t.integer "report_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "formatter", limit: 255
    t.integer "numeric_precision"
    t.integer "sort_order"
    t.boolean "group_by", default: false
    t.string "alias_name", limit: 255
    t.index ["report_id"], name: "index_reporting_output_fields_on_report_id"
  end

  create_table "reporting_reports", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "description", limit: 255
    t.string "data_source", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "primary_key", limit: 255, default: "id", null: false
  end

  create_table "reporting_specific_filter_groups", id: :serial, force: :cascade do |t|
    t.integer "report_id"
    t.integer "filter_group_id"
    t.integer "sort_order", default: 1, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["filter_group_id"], name: "index_of_filter_group_on_specific_filter_group"
    t.index ["report_id"], name: "index_of_report_on_specific_filter_group"
  end

  create_table "ridership_mobility_mappings", id: :serial, force: :cascade do |t|
    t.integer "ridership_id"
    t.integer "mobility_id"
    t.integer "capacity"
    t.string "type", limit: 255
    t.integer "host_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["mobility_id"], name: "index_ridership_mobility_mappings_on_mobility_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "provider_id"
    t.integer "level"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_roles_on_deleted_at"
    t.index ["provider_id"], name: "index_roles_on_provider_id"
    t.index ["user_id"], name: "index_roles_on_user_id"
  end

  create_table "run_distances", id: :serial, force: :cascade do |t|
    t.float "total_dist"
    t.float "revenue_miles"
    t.float "non_revenue_miles"
    t.float "deadhead_from_garage"
    t.float "deadhead_to_garage"
    t.integer "run_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float "passenger_miles"
    t.float "ntd_total_miles"
    t.float "ntd_total_revenue_miles"
    t.float "ntd_total_passenger_miles"
    t.float "ntd_total_hours"
    t.float "ntd_total_revenue_hours"
  end

  create_table "run_vehicle_inspections", force: :cascade do |t|
    t.bigint "run_id"
    t.bigint "vehicle_inspection_id"
    t.boolean "checked"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["run_id"], name: "index_run_vehicle_inspections_on_run_id"
    t.index ["vehicle_inspection_id"], name: "index_run_vehicle_inspections_on_vehicle_inspection_id"
  end

  create_table "runs", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.date "date"
    t.integer "start_odometer"
    t.integer "end_odometer"
    t.datetime "scheduled_start_time"
    t.datetime "scheduled_end_time"
    t.integer "unpaid_driver_break_time"
    t.integer "vehicle_id"
    t.integer "driver_id"
    t.boolean "paid"
    t.boolean "complete"
    t.integer "provider_id"
    t.datetime "actual_start_time"
    t.datetime "actual_end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lock_version", default: 0
    t.integer "repeating_run_id"
    t.datetime "deleted_at"
    t.text "manifest_order"
    t.boolean "cancelled"
    t.integer "from_garage_address_id"
    t.integer "to_garage_address_id"
    t.text "uncomplete_reason"
    t.string "scheduled_start_time_string", limit: 255
    t.string "scheduled_end_time_string", limit: 255
    t.text "driver_notes"
    t.datetime "manifest_published_at"
    t.boolean "manifest_changed"
    t.index ["deleted_at"], name: "index_runs_on_deleted_at"
    t.index ["driver_id"], name: "index_runs_on_driver_id"
    t.index ["from_garage_address_id"], name: "index_runs_on_from_garage_address_id"
    t.index ["provider_id", "date"], name: "index_runs_on_provider_id_and_date"
    t.index ["provider_id", "scheduled_start_time"], name: "index_runs_on_provider_id_and_scheduled_start_time"
    t.index ["repeating_run_id"], name: "index_runs_on_repeating_run_id"
    t.index ["to_garage_address_id"], name: "index_runs_on_to_garage_address_id"
    t.index ["vehicle_id"], name: "index_runs_on_vehicle_id"
  end

  create_table "saved_custom_reports", id: :serial, force: :cascade do |t|
    t.integer "custom_report_id"
    t.integer "provider_id"
    t.string "name", limit: 255
    t.integer "date_range_type"
    t.text "report_params"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["custom_report_id"], name: "index_saved_custom_reports_on_custom_report_id"
    t.index ["provider_id"], name: "index_saved_custom_reports_on_provider_id"
  end

  create_table "service_levels", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_service_levels_on_deleted_at"
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.string "var", limit: 255, null: false
    t.text "value"
    t.integer "thing_id"
    t.string "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true
  end

  create_table "translation_keys", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translations", id: :serial, force: :cascade do |t|
    t.integer "locale_id"
    t.integer "translation_key_id"
    t.text "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "travel_time_estimates", id: false, force: :cascade do |t|
    t.integer "from_address_id"
    t.integer "to_address_id"
    t.integer "seconds"
  end

  create_table "travel_trainings", id: :serial, force: :cascade do |t|
    t.integer "customer_id"
    t.datetime "date"
    t.text "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["customer_id"], name: "index_travel_trainings_on_customer_id"
  end

  create_table "trip_purposes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_trip_purposes_on_deleted_at"
  end

  create_table "trip_results", id: :serial, force: :cascade do |t|
    t.string "code", limit: 255
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string "description", limit: 255
    t.index ["deleted_at"], name: "index_trip_results_on_deleted_at"
  end

  create_table "trips", id: :serial, force: :cascade do |t|
    t.integer "run_id"
    t.integer "customer_id"
    t.datetime "pickup_time"
    t.datetime "appointment_time"
    t.integer "guest_count", default: 0
    t.integer "attendant_count", default: 0
    t.integer "group_size", default: 0
    t.integer "pickup_address_id"
    t.integer "dropoff_address_id"
    t.integer "mobility_id"
    t.integer "funding_source_id"
    t.string "trip_purpose_old", limit: 255
    t.string "trip_result_old", limit: 255, default: ""
    t.text "notes"
    t.decimal "donation_old", precision: 10, scale: 2, default: "0.0"
    t.integer "provider_id"
    t.datetime "called_back_at"
    t.boolean "customer_informed", default: false
    t.integer "repeating_trip_id"
    t.boolean "cab", default: false
    t.boolean "cab_notified", default: false
    t.text "guests"
    t.integer "called_back_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lock_version", default: 0
    t.boolean "medicaid_eligible"
    t.integer "mileage"
    t.string "service_level_old", limit: 255
    t.integer "trip_purpose_id"
    t.integer "trip_result_id"
    t.integer "service_level_id"
    t.datetime "deleted_at"
    t.string "direction", limit: 255, default: "outbound"
    t.text "result_reason"
    t.integer "linking_trip_id"
    t.float "drive_distance"
    t.integer "mobility_device_accommodations"
    t.integer "number_of_senior_passengers_served"
    t.integer "number_of_disabled_passengers_served"
    t.integer "number_of_low_income_passengers_served"
    t.string "pickup_address_notes", limit: 255
    t.string "dropoff_address_notes", limit: 255
    t.boolean "is_stand_by"
    t.boolean "driver_notified"
    t.integer "customer_space_count"
    t.integer "service_animal_space_count"
    t.integer "passenger_load_min"
    t.integer "passenger_unload_min"
    t.boolean "early_pickup_allowed"
    t.bigint "fare_id"
    t.float "fare_amount"
    t.datetime "fare_collected_time"
    t.index ["called_back_by_id"], name: "index_trips_on_called_back_by_id"
    t.index ["customer_id"], name: "index_trips_on_customer_id"
    t.index ["deleted_at"], name: "index_trips_on_deleted_at"
    t.index ["dropoff_address_id"], name: "index_trips_on_dropoff_address_id"
    t.index ["fare_id"], name: "index_trips_on_fare_id"
    t.index ["funding_source_id"], name: "index_trips_on_funding_source_id"
    t.index ["linking_trip_id"], name: "index_trips_on_linking_trip_id"
    t.index ["mobility_id"], name: "index_trips_on_mobility_id"
    t.index ["pickup_address_id"], name: "index_trips_on_pickup_address_id"
    t.index ["provider_id", "appointment_time"], name: "index_trips_on_provider_id_and_appointment_time"
    t.index ["provider_id", "pickup_time"], name: "index_trips_on_provider_id_and_pickup_time"
    t.index ["repeating_trip_id"], name: "index_trips_on_repeating_trip_id"
    t.index ["run_id"], name: "index_trips_on_run_id"
    t.index ["service_level_id"], name: "index_trips_on_service_level_id"
    t.index ["trip_purpose_id"], name: "index_trips_on_trip_purpose_id"
    t.index ["trip_result_id"], name: "index_trips_on_trip_result_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "reset_password_token", limit: 255
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.string "password_salt", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "current_provider_id"
    t.string "unconfirmed_email", limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "password_changed_at"
    t.datetime "expires_at"
    t.string "inactivation_reason", limit: 255
    t.datetime "deleted_at"
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.string "username", limit: 255
    t.string "phone_number", limit: 255
    t.integer "address_id"
    t.string "authentication_token", limit: 30
    t.index ["address_id"], name: "index_users_on_address_id"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["current_provider_id"], name: "index_users_on_current_provider_id"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["password_changed_at"], name: "index_users_on_password_changed_at"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vehicle_capacity_configurations", id: :serial, force: :cascade do |t|
    t.integer "vehicle_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["vehicle_type_id"], name: "index_vehicle_capacity_configurations_on_vehicle_type_id"
  end

  create_table "vehicle_compliances", id: :serial, force: :cascade do |t|
    t.integer "vehicle_id"
    t.string "event", limit: 255
    t.text "notes"
    t.date "due_date"
    t.date "compliance_date"
    t.integer "vehicle_requirement_template_id"
    t.boolean "legal"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["vehicle_id"], name: "index_vehicle_compliances_on_vehicle_id"
    t.index ["vehicle_requirement_template_id"], name: "index_vehicle_compliances_on_vehicle_requirement_template_id"
  end

  create_table "vehicle_inspections", force: :cascade do |t|
    t.string "description"
    t.datetime "deleted_at"
    t.bigint "provider_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "flagged"
    t.boolean "mechanical"
    t.index ["provider_id"], name: "index_vehicle_inspections_on_provider_id"
  end

  create_table "vehicle_maintenance_compliance_due_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 16
    t.string "note", limit: 16
  end

  create_table "vehicle_maintenance_compliances", id: :serial, force: :cascade do |t|
    t.integer "vehicle_id"
    t.string "event", limit: 255
    t.text "notes"
    t.date "due_date"
    t.integer "due_mileage"
    t.string "due_type", limit: 255
    t.date "compliance_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "recurring_vehicle_maintenance_compliance_id"
    t.integer "compliance_mileage"
    t.integer "vehicle_maintenance_schedule_id"
    t.index ["recurring_vehicle_maintenance_compliance_id"], name: "index_vehicle_maintenance_compliances_on_recurring_vehicle_main"
    t.index ["vehicle_id"], name: "index_vehicle_maintenance_compliances_on_vehicle_id"
    t.index ["vehicle_maintenance_schedule_id"], name: "index_compl_veh_maint_sched_id"
  end

  create_table "vehicle_maintenance_events", id: :serial, force: :cascade do |t|
    t.integer "vehicle_id"
    t.boolean "reimbursable"
    t.date "service_date"
    t.date "invoice_date"
    t.text "services_performed"
    t.decimal "odometer", precision: 10, scale: 1
    t.string "vendor_name", limit: 255
    t.string "invoice_number", limit: 255
    t.decimal "invoice_amount", precision: 10, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lock_version", default: 0
    t.index ["vehicle_id"], name: "index_vehicle_maintenance_events_on_vehicle_id"
  end

  create_table "vehicle_maintenance_schedule_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "provider_id"
    t.index ["provider_id"], name: "index_veh_maint_sched_type_provider_id"
  end

  create_table "vehicle_maintenance_schedules", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "mileage"
    t.integer "vehicle_maintenance_schedule_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["vehicle_maintenance_schedule_type_id"], name: "index_vehicle_maintenance_schedule_type_id"
  end

  create_table "vehicle_monthly_trackings", id: :serial, force: :cascade do |t|
    t.integer "provider_id"
    t.integer "year"
    t.integer "month"
    t.integer "max_available_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider_id"], name: "index_vehicle_monthly_trackings_on_provider_id"
  end

  create_table "vehicle_requirement_templates", id: :serial, force: :cascade do |t|
    t.integer "provider_id"
    t.string "name", limit: 255
    t.boolean "legal"
    t.boolean "reoccuring"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider_id"], name: "index_vehicle_requirement_templates_on_provider_id"
  end

  create_table "vehicle_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider_id"], name: "index_vehicle_types_on_provider_id"
  end

  create_table "vehicle_warranties", id: :serial, force: :cascade do |t|
    t.integer "vehicle_id"
    t.string "description", limit: 255
    t.text "notes"
    t.date "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["vehicle_id"], name: "index_vehicle_warranties_on_vehicle_id"
  end

  create_table "vehicle_warranty_templates", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "provider_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider_id"], name: "index_vehicle_warranty_templates_on_provider_id"
  end

  create_table "vehicles", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "year"
    t.string "make", limit: 255
    t.string "model", limit: 255
    t.string "license_plate", limit: 255
    t.string "vin", limit: 255
    t.string "garaged_location", limit: 255
    t.integer "provider_id"
    t.boolean "active", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lock_version", default: 0
    t.integer "default_driver_id"
    t.boolean "reportable", default: true
    t.text "insurance_coverage_details"
    t.string "ownership", limit: 255
    t.string "responsible_party", limit: 255
    t.date "registration_expiration_date"
    t.integer "seating_capacity"
    t.text "accessibility_equipment"
    t.datetime "deleted_at"
    t.integer "mobility_device_accommodations"
    t.integer "initial_mileage", default: 0
    t.integer "garage_address_id"
    t.string "garage_phone_number", limit: 255
    t.text "initial_mileage_change_reason"
    t.date "inactivated_start_date"
    t.date "inactivated_end_date"
    t.text "active_status_changed_reason"
    t.integer "vehicle_maintenance_schedule_type_id"
    t.integer "vehicle_type_id"
    t.boolean "is_5310_reportable", default: true
    t.index ["default_driver_id"], name: "index_vehicles_on_default_driver_id"
    t.index ["deleted_at"], name: "index_vehicles_on_deleted_at"
    t.index ["garage_address_id"], name: "index_vehicles_on_garage_address_id"
    t.index ["provider_id"], name: "index_vehicles_on_provider_id"
    t.index ["vehicle_maintenance_schedule_type_id"], name: "index_veh_maint_sched_type_id"
    t.index ["vehicle_type_id"], name: "index_vehicles_on_vehicle_type_id"
  end

  create_table "verification_questions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.text "question"
    t.text "answer"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_verification_questions_on_user_id"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", limit: 255, null: false
    t.integer "item_id", null: false
    t.string "event", limit: 255, null: false
    t.string "whodunnit", limit: 255
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "weekday_assignments", id: :serial, force: :cascade do |t|
    t.integer "repeating_trip_id"
    t.integer "repeating_run_id"
    t.integer "wday"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["repeating_run_id"], name: "index_weekday_assignments_on_repeating_run_id"
    t.index ["repeating_trip_id"], name: "index_weekday_assignments_on_repeating_trip_id"
  end

  add_foreign_key "chat_read_receipts", "messages"
  add_foreign_key "chat_read_receipts", "runs"
  add_foreign_key "gps_locations", "providers"
  add_foreign_key "gps_locations", "runs"
  add_foreign_key "message_templates", "providers"
  add_foreign_key "messages", "drivers"
  add_foreign_key "messages", "runs"
  add_foreign_key "run_vehicle_inspections", "runs"
  add_foreign_key "run_vehicle_inspections", "vehicle_inspections"
  add_foreign_key "vehicle_inspections", "providers"
end
