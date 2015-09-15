class RemoveDeletedAtFromLookupTables < ActiveRecord::Migration
  def change
    remove_column :lookup_tables, :deleted_at
  end
end
