class AddNewFieldsToVehicles < ActiveRecord::Migration
  def change
    add_column :vehicles, :insurance_coverage_details, :text
    add_column :vehicles, :ownership, :string
    add_column :vehicles, :responsible_party, :string
    add_column :vehicles, :registration_expiration_date, :date
    add_column :vehicles, :seating_capacity, :integer
    add_column :vehicles, :accessibility_equipment, :text
  end
end
