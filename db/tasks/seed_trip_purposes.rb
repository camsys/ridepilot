TRIP_PURPOSES = [
  "Life-Sustaining Medical", 
  "Medical", 
  "Nutrition", 
  "Personal/Support Services", 
  "Recreation", 
  "School/Work", 
  "Shopping", 
  "Volunteer Work", 
  "Center"] if !defined?(TRIP_PURPOSES)
  
TRIP_PURPOSES.each do |tp_name|
  TripPurpose.where(name: tp_name).first_or_create
end

# migrate existing trip_purpose data in trips, repeating_trips, address table
Trip.all.each do |trip|
  trip.update trip_purpose: TripPurpose.find_by(name: trip.trip_purpose_old)
end
RepeatingTrip.all.each do |trip|
  trip.update trip_purpose: TripPurpose.find_by(name: trip.trip_purpose_old)
end
Address.all.each do |addr|
  addr.update trip_purpose: TripPurpose.find_by(name: addr.trip_purpose_old)
end