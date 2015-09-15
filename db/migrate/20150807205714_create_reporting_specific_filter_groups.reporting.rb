# This migration comes from reporting (originally 20150414180638)
class CreateReportingSpecificFilterGroups < ActiveRecord::Migration
  def up
    create_table :reporting_specific_filter_groups do |t|
      t.references :report
      t.references :filter_group
      t.integer :sort_order, null: false, default: 1

      t.timestamps
    end

    add_index :reporting_specific_filter_groups, :report_id, name: 'index_of_report_on_specific_filter_group'
    add_index :reporting_specific_filter_groups, :filter_group_id, name: 'index_of_filter_group_on_specific_filter_group'

    remove_column :reporting_filter_groups, :sort_order
  end

  def down
    add_column :reporting_filter_groups, :sort_order, :integer, null: false, default: 1

    drop_table :reporting_specific_filter_groups
  end
end
