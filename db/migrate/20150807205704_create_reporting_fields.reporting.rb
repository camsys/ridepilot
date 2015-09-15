# This migration comes from reporting (originally 20150328212122)
class CreateReportingFields < ActiveRecord::Migration
  def change
    create_table :reporting_fields do |t|
      t.references :filter_group, index: true, foreign_key: true, null: false
      t.references :filter_type, index: true, foreign_key: true, null: false
      t.references :lookup_table, index: true, foreign_key: true
      t.string :name, null: false
      t.string :alias
      t.boolean :is_filterable
      t.boolean :is_output
      t.boolean :is_validate

      t.timestamps null: false
    end
  end
end
