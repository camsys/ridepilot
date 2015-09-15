# This migration comes from reporting (originally 20150328210013)
class CreateReportingReports < ActiveRecord::Migration
  def change
    create_table :reporting_reports do |t|
      t.string :name, null: false
      t.string :description
      t.string :data_source, null: false

      t.timestamps null: false
    end
  end
end
