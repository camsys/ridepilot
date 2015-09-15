class CreateVehicleMaintenanceCompliances < ActiveRecord::Migration
  def change
    create_table :vehicle_maintenance_compliances do |t|
      t.references :vehicle, index: true
      t.string :event
      t.text :notes
      t.date :due_date
      t.integer :due_mileage
      t.string :due_type
      t.date :compliance_date

      t.timestamps
    end
  end
end
