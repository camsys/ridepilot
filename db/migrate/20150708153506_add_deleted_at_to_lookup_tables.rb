class AddDeletedAtToLookupTables < ActiveRecord::Migration
  def change
    add_column :trip_purposes, :deleted_at, :datetime
    add_index :trip_purposes, :deleted_at
    add_column :trip_results, :deleted_at, :datetime
    add_index :trip_results, :deleted_at
    add_column :service_levels, :deleted_at, :datetime
    add_index :service_levels, :deleted_at
    add_column :mobilities, :deleted_at, :datetime
    add_index :mobilities, :deleted_at
  end
end
