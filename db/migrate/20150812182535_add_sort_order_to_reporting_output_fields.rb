class AddSortOrderToReportingOutputFields < ActiveRecord::Migration
  def change
    add_column :reporting_output_fields, :sort_order, :integer
  end
end
