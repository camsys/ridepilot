class AddDataAccessFieldsToReportingLookupTables < ActiveRecord::Migration
  def change
    add_column :reporting_lookup_tables, :data_access_type, :string
  end
end
