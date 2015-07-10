SERVICE_LEVELS = ["Wheelchair", "Ambulatory"] if !defined?(SERVICE_LEVELS)
  
SERVICE_LEVELS.each do |level|
  ServiceLevel.where(name: level).first_or_create
end

# migrate existing service_level data in trips, customers table
Trip.all.each do |trip|
  trip.update service_level: ServiceLevel.find_by(name: trip.service_level_old)
end

Customer.all.each do |customer|
  customer.update service_level: ServiceLevel.find_by(name: customer.service_level_old)
end