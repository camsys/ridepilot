class AddComplianceMileageToVehicleMaintenanceCompliances < ActiveRecord::Migration
  def change
    add_column :vehicle_maintenance_compliances, :compliance_mileage, :integer
  end
end
