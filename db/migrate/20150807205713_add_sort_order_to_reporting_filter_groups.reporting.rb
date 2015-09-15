# This migration comes from reporting (originally 20150414142007)
class AddSortOrderToReportingFilterGroups < ActiveRecord::Migration
  def change
    add_column :reporting_filter_groups, :sort_order, :integer, null: false, default: 1
  end
end
