require 'json'
require 'net/http'

class AbstractDistanceDurationService
  attr_reader :from_lat, :from_lon, :to_lat, :to_lon, :trip_datetime

  METERS_TO_MILES = 0.000621371192

  def initialize(from_lat, from_lon, to_lat, to_lon, trip_datetime)
    @from_lat = from_lat
    @from_lon = from_lon
    @to_lat = to_lat
    @to_lon = to_lon
    @trip_datetime = trip_datetime || DateTime.now
  end

  def get_drive_itineraries(try_count=3)
    return nil unless params_valid?

    try = 1
    result = nil
    response = nil

    while try <= try_count
      result, response = get_drive_itineraries_once
      if result
        break
      else
        Rails.logger.info [@from_lat, @from_lon, @to_lat, @to_lon, @trip_datetime]
        Rails.logger.info response
        Rails.logger.info "Try " + try.to_s + " failed."
        Rails.logger.info "Trying again..."

      end
      sleep([try,3].min) #The first time wait 1 second, the second time wait 2 seconds, wait 3 seconds every time after that.
      try +=1
    end

    return result, response

  end

  # in seconds
  def get_drive_time
    return nil if !params_valid?

    result, response = get_drive_itineraries
    
    send(:parse_drive_time, response) if result
  end

  # in miles
  def get_drive_distance
    return nil if !params_valid?

    result, response = get_drive_itineraries

    send(:parse_drive_distance, response) if result
  end

  private

  def params_valid?
    @from_lon && @from_lat && @to_lat && @to_lon && @trip_datetime
  end

  def get_drive_itineraries_once
    url = build_url
    Rails.logger.info url
   
    t = Time.current
    begin
      resp = Net::HTTP.get_response(URI.parse(url))
      Rails.logger.info(resp[:ai])
    rescue Exception=>e
      Rails.logger.error "Service failure(url: #{url}): fixed: #{e.message}"
      return false, {'id'=>500, 'msg'=>e.to_s}
    end

    if resp.code != "200"
      Rails.logger.error "Service failure: fixed: resp.code not 200, #{resp.message}"
      return false, {'id'=>resp.code.to_i, 'msg'=>resp.message}
    end

    data = resp.body
    result = JSON.parse(data)
    
    send(:parse_response, result)
  end

end
