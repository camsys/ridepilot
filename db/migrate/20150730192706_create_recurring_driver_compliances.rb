class CreateRecurringDriverCompliances < ActiveRecord::Migration
  def change
    create_table :recurring_driver_compliances do |t|
      t.references :provider, index: true
      t.string :event_name, nil: false
      t.text :event_notes
      t.string :recurrence_schedule, nil: false
      t.integer :recurrence_frequency, nil: false
      t.text :recurrence_notes
      t.date :start_date, nil: false
      t.string :future_start_rule, nil: false
      t.string :future_start_schedule
      t.integer :future_start_frequency
      t.boolean :compliance_date_based_scheduling, nil: false, default: false

      t.timestamps
    end
    
    add_reference :driver_compliances, :recurring_driver_compliance, index: true
  end
end