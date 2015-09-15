class CreateRepeatingRuns < ActiveRecord::Migration
  def change
    create_table :repeating_runs do |t|
      t.text :schedule_yaml
      t.string :name
      t.date :date
      t.datetime :scheduled_start_time
      t.datetime :scheduled_end_time
      t.references :vehicle, index: true
      t.references :driver, index: true
      t.boolean :paid
      t.references :provider, index: true
      t.integer :lock_version, default: 0

      t.timestamps
    end
    
    add_column :runs, :repeating_run_id, :integer
    add_index :runs, :repeating_run_id
  end
end