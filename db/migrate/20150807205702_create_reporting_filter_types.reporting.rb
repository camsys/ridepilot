# This migration comes from reporting (originally 20150328210235)
class CreateReportingFilterTypes < ActiveRecord::Migration
  def change
    create_table :reporting_filter_types do |t|
      t.string :name, null: false
      t.string :partial
      t.string :formatter

      t.timestamps null: false
    end
  end
end
