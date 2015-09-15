class AddProviderSpecificToLookupTables < ActiveRecord::Migration
  def change
    add_column :lookup_tables, :is_provider_specific, :boolean, default: false
    add_column :lookup_tables, :model_name, :string
  end
end
