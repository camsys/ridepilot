module ReportsHelper
  def reimbursement_rate(reimbursement_rate_attribute)
    if reimbursement_rate_attribute.present?
      number_to_currency(reimbursement_rate_attribute, :precesion => 2)
    else
      "*"
    end
  end

  def reimbursement_due(reimbursement_due, reimbursement_rate_attributes)
    if reimbursement_rate_attributes.nil? || Array(reimbursement_rate_attributes).select(&:nil?).count > 0
      "*"
    else
      number_to_currency(reimbursement_due, :precesion => 2)
    end
  end
  
  def later_trips_for_customer(customer, trip)
    return [] unless @trips_by_customer.any?
    @trips_by_customer[customer].select{ |ot| ot.pickup_time > trip.pickup_time }
  end
  
  def ordered_pickup_and_dropoff_addresses(trips)
    trips.collect do |trip|
      [{time: trip.pickup_time, address: trip.pickup_address}, {time: trip.appointment_time, address: trip.dropoff_address}]
    end.flatten.sort_by{ |trip_info| trip_info[:time] }.collect{ |trip_info| trip_info[:address] }
  end
end
