class CreateReports < ActiveRecord::Migration
  def change
    create_table :custom_reports do |t|
      t.string :name

      t.timestamps
    end
  end
end
