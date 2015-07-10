class AddReferenceIndex < ActiveRecord::Migration
  def change
    add_index :addresses, :provider_id
    add_index :customers, :address_id
    add_index :customers, :mobility_id
    add_index :customers, :provider_id
    add_index :customers, :default_funding_source_id
    add_index :device_pool_drivers, :vehicle_id
    add_index :device_pools, :provider_id
    add_index :drivers, :provider_id
    add_index :drivers, :user_id
    add_index :funding_source_visibilities, :funding_source_id
    add_index :funding_source_visibilities, :provider_id
    add_index :monthlies, :provider_id
    add_index :monthlies, :funding_source_id
    add_index :provider_ethnicities, :provider_id
    add_index :repeating_trips, :provider_id
    add_index :repeating_trips, :customer_id
    add_index :repeating_trips, :pickup_address_id
    add_index :repeating_trips, :dropoff_address_id
    add_index :repeating_trips, :mobility_id
    add_index :repeating_trips, :funding_source_id
    add_index :repeating_trips, :driver_id
    add_index :repeating_trips, :vehicle_id
    add_index :roles, :user_id
    add_index :roles, :provider_id
    add_index :runs, :vehicle_id
    add_index :runs, :driver_id
    add_index :trips, :customer_id
    add_index :trips, :pickup_address_id
    add_index :trips, :dropoff_address_id
    add_index :trips, :mobility_id
    add_index :trips, :funding_source_id
    add_index :trips, :repeating_trip_id
    add_index :trips, :run_id
    add_index :trips, :called_back_by_id
    add_index :users, :current_provider_id
    add_index :vehicle_maintenance_events, :provider_id
    add_index :vehicle_maintenance_events, :vehicle_id
    add_index :vehicles, :provider_id
    add_index :vehicles, :default_driver_id
  end
end
