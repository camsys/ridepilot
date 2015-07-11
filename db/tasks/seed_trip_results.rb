TRIP_RESULT_CODES = {
  "COMP"  => "Complete",    # the trip was (as far as we know) completed
  "NS"    => "No-show",     # the customer did not show up for the trip
  "CANC"  => "Cancelled",   # the trip was cancelled by the customer
  "TD"    => "Turned down", # the provider told the customer that it could not provide the trip
  "UNMET" => "Unmet Need"   # a trip that was outside of the service parameters (too early, too late, too far, etc).
} if !defined?(TRIP_RESULT_CODES)
  
TRIP_RESULT_CODES.each do |code, text|
  result = TripResult.where(code: code).first_or_create.update(name: text)
end

# migrate existing trip_result data in Trips table
Trip.all.each do |trip|
  trip.update trip_result: TripResult.find_by(code: trip.trip_result_old)
end