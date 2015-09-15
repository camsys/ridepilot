# This migration comes from reporting (originally 20150407210447)
class RemoveColumnsFromReportingFilterType < ActiveRecord::Migration
  def up
    remove_column :reporting_filter_types, :formatter
    remove_column :reporting_filter_types, :partial
  end

  def down
    add_column :reporting_filter_types, :partial, :string
    add_column :reporting_filter_types, :formatter, :string
  end
end
