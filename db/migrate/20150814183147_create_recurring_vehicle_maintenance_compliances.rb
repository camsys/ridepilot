class CreateRecurringVehicleMaintenanceCompliances < ActiveRecord::Migration
  def change
    create_table :recurring_vehicle_maintenance_compliances do |t|
      t.references :provider, index: true
      t.string :event_name
      t.text :event_notes
      t.string :recurrence_type
      t.string :recurrence_schedule
      t.integer :recurrence_frequency
      t.integer :recurrence_mileage
      t.text :recurrence_notes
      t.date :start_date
      t.string :future_start_rule
      t.string :future_start_schedule
      t.integer :future_start_frequency
      t.boolean :compliance_based_scheduling

      t.timestamps
    end
  end
end
