class CreateTripPurposes < ActiveRecord::Migration
  def change
    create_table :trip_purposes do |t|
      t.string :name

      t.timestamps
    end
  end
end
