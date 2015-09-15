# This migration comes from reporting (originally 20150415185638)
class AddValueTypeToReportingFilterFields < ActiveRecord::Migration
  def change
    add_column :reporting_filter_fields, :value_type, :string
  end
end
