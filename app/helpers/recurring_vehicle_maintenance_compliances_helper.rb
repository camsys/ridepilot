module RecurringVehicleMaintenanceCompliancesHelper
  def schedule_string(recurring_vehicle_maintenance_compliance)
    date_schedule = "#{recurring_vehicle_maintenance_compliance.recurrence_frequency} #{recurring_vehicle_maintenance_compliance.recurrence_schedule}" rescue nil
    mileage_schedule = "#{number_with_delimiter recurring_vehicle_maintenance_compliance.recurrence_mileage} mi" rescue nil
    case recurring_vehicle_maintenance_compliance.recurrence_type.try(:to_sym)
    when :date
      date_schedule
    when :mileage
      mileage_schedule
    when :both
      "#{date_schedule} and #{mileage_schedule}"
    end
  end
end
