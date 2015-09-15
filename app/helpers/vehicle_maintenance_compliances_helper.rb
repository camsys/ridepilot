module VehicleMaintenanceCompliancesHelper
  def due_string(vehicle_maintenance_compliance)
    date = vehicle_maintenance_compliance.due_date.try(:to_s, :long)
    mileage = "#{number_with_delimiter vehicle_maintenance_compliance.due_mileage} mi"
    case vehicle_maintenance_compliance.due_type.try(:to_sym)
    when :date
      date
    when :mileage
      mileage
    when :both
      "#{date} and #{mileage}"
    end
  end
end
