class AddRecurringVehicleMaintenanceComplianceIdToVehicleMaintenanceCompliances < ActiveRecord::Migration
  def change
    # Disable automatic index creation, otherwise we get an error:
    #   Index name '...' on table 'vehicle_maintenance_compliances' is too 
    #   long; the limit is 63 characters
    add_reference :vehicle_maintenance_compliances, :recurring_vehicle_maintenance_compliance, index: false
    add_index :vehicle_maintenance_compliances, :recurring_vehicle_maintenance_compliance_id, name: "index_vehicle_maintenance_compliances_on_recurring_vehicle_main"
  end
end
