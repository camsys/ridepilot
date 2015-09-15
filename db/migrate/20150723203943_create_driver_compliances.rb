class CreateDriverCompliances < ActiveRecord::Migration
  def change
    create_table :driver_compliances do |t|
      t.references :driver, index: true
      t.string :event
      t.text :notes
      t.date :due_date
      t.date :compliance_date

      t.timestamps
    end
  end
end
