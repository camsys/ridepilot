# This migration comes from reporting (originally 20150401144656)
class CreateReportingOutputFields < ActiveRecord::Migration
  def change
    create_table :reporting_output_fields do |t|
      t.string :name, null: false
      t.string :title
      t.references :report, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end
  end
end
