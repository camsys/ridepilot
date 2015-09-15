class CreateVehicleWarranties < ActiveRecord::Migration
  def change
    create_table :vehicle_warranties do |t|
      t.references :vehicle, index: true
      t.string :description
      t.text :notes
      t.date :expiration_date

      t.timestamps
    end
  end
end
