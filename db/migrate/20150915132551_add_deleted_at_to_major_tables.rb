class AddDeletedAtToMajorTables < ActiveRecord::Migration
  def change
    add_column :addresses, :deleted_at, :datetime
    add_column :customers, :deleted_at, :datetime
    add_column :device_pools, :deleted_at, :datetime
    add_column :drivers, :deleted_at, :datetime
    add_column :funding_sources, :deleted_at, :datetime
    add_column :providers, :deleted_at, :datetime
    add_column :provider_ethnicities, :deleted_at, :datetime
    add_column :regions, :deleted_at, :datetime
    add_column :runs, :deleted_at, :datetime
    add_column :trips, :deleted_at, :datetime
    add_column :users, :deleted_at, :datetime
    add_column :roles, :deleted_at, :datetime
    add_column :vehicles, :deleted_at, :datetime


    add_index :addresses, :deleted_at
    add_index :customers, :deleted_at
    add_index :device_pools, :deleted_at
    add_index :drivers, :deleted_at
    add_index :funding_sources, :deleted_at
    add_index :providers, :deleted_at
    add_index :provider_ethnicities, :deleted_at
    add_index :regions, :deleted_at
    add_index :runs, :deleted_at
    add_index :trips, :deleted_at
    add_index :users, :deleted_at
    add_index :roles, :deleted_at
    add_index :vehicles, :deleted_at
  end
end
