class AddDeletedAtToLookupConfigurationTable < ActiveRecord::Migration
  def change
    add_column :lookup_tables, :deleted_at, :datetime
    add_index :lookup_tables, :deleted_at
  end
end
