class CreateOperatingHours < ActiveRecord::Migration
  def change
    create_table :operating_hours do |t|
      t.references :driver, index: true
      t.integer :day_of_week
      t.time :start_time
      t.time :end_time

      t.timestamps
    end
  end
end
