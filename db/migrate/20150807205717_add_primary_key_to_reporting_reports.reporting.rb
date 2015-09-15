# This migration comes from reporting (originally 20150422175448)
class AddPrimaryKeyToReportingReports < ActiveRecord::Migration
  def change
    add_column :reporting_reports, :primary_key, :string, null: false, default: 'id'
  end
end
