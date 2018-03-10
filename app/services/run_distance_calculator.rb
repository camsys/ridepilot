require 'json'
require 'net/http'

class RunDistanceCalculator
  attr_reader :run

  def initialize(run_id)
    @run = Run.find_by_id(run_id)
  end

  def process
    return unless @run && @run.complete?

    itins = get_itineraries(@run)

    return if itins.empty?

    total_dist = 0
    deadhead_from_garage = 0
    revenuse_miles = 0
    non_revenue_miles = 0
    deadhead_to_garage = 0

    from_address = @run.from_garage_address || @run.vehicle.try(:garage_address)
    to_address = itins[0][:address]
    time = @run.scheduled_start_time
    
    deadhead_from_garage = get_drive_distance(from_address, to_address, time)

    itin_count = itins.size
    itins.each_with_index do |itin, index|
      next if index < 1

      from_address = itins[index - 1][:address]
      to_address = itin[:address]
      time = itin[:time]

      dist = get_drive_distance(from_address, to_address, time)
      if itin[:capacity] > 0
        revenuse_miles += dist 
      else
        non_revenue_miles += dist
      end         
    end

    last_stop = itins.last
    from_address = last_stop[:address]
    to_address = @run.to_garage_address || @run.vehicle.try(:garage_address)
    time = last_stop[:time]
    deadhead_to_garage = get_drive_distance(from_address, to_address, time)

    total_dist = deadhead_from_garage + revenuse_miles + non_revenue_miles + deadhead_to_garage

    run_distance = @run.run_distance || RunDistance.new(run: @run)
    run_distance.total_dist = total_dist
    run_distance.revenue_miles = revenuse_miles
    run_distance.non_revenue_miles = non_revenue_miles
    run_distance.deadhead_from_garage = deadhead_from_garage
    run_distance.deadhead_to_garage = deadhead_to_garage
    run_distance.save
  end

  

  def get_itineraries(run)
    return [] unless run

    itins = []

    manifest_order = run.manifest_order

    run.trips.each do |trip|
      trip_data = {
        trip: trip
      }

      pickup_sort_key = time_portion(trip.pickup_time)
      itin_id = "trip_#{trip.id}_leg_1"
      itins << trip_data.merge(
        id: itin_id,
        ordinal: (manifest_order.try(:index, itin_id) || -1),
        leg_flag: 1,
        time: trip.pickup_time,
        sort_key: pickup_sort_key,
        address: trip.pickup_address
      )

      if !TripResult::CANCEL_CODES_BUT_KEEP_RUN.include?(trip.trip_result.try(:code))
        dropoff_sort_key = trip.appointment_time ? time_portion(trip.appointment_time) : time_portion(trip.pickup_time)
        do_itin_id = "trip_#{trip.id}_leg_2"
        itins << trip_data.merge(
          id: do_itin_id,
          ordinal: (manifest_order.try(:index, do_itin_id) || -1),
          leg_flag: 2,
          time: trip.appointment_time,
          sort_key: dropoff_sort_key,
          address: trip.dropoff_address
        )
      end
    end

    itins = if manifest_order && manifest_order.any?
      itins.sort_by { |itin| [itin[:ordinal] >= 0 ? 0 : 1, itin[:ordinal], itin[:sort_key], itin[:leg_flag]] }
    else
      itins.sort_by { |itin| [itin[:sort_key], itin[:leg_flag]] }
    end
    # calculate occupancy
    occupancy = 0
    delta = 0
    itins.each do |itin|
      trip = itin[:trip]
      occupancy += delta
      itin[:capacity] = occupancy

      if TripResult::NON_DISPATCHABLE_CODES.include?(trip.trip_result.try(:code))
        delta = 0
      elsif itin[:leg_flag] == 1
        delta = trip.trip_size 
      elsif itin[:leg_flag] == 2
        delta = -1 * trip.trip_size
      end
    end

    itins
  end

  def get_drive_distance(from_addr, to_addr, time = DateTime.now)
    from_lat = from_addr.try(:latitude)
    from_lon = from_addr.try(:longitude)
    to_lat = to_addr.try(:latitude)
    to_lon = to_addr.try(:longitude)

    return 0 unless from_lat && from_lon && to_lat && to_lon

    TripPlanner.new(from_lat, from_lon, to_lat, to_lon, time).get_drive_distance.to_f
  end

  def time_portion(time)
    (time - time.beginning_of_day) if time
  end
end
