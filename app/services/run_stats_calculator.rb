require 'json'
require 'net/http'

class RunStatsCalculator
  attr_reader :run

  def initialize(run_id)
    @run = Run.find_by_id(run_id)
  end

  # calculate run distances
  #    total, revenue, non-revenue, deadhead, passenger miles
  def process_distance
    return unless @run && @run.complete?

    itins = @run.sorted_itineraries(true)
    itins = append_capacity_to_itineraries(itins)

    return if itins.empty?

    total_dist = 0
    deadhead_from_garage = 0
    revenuse_miles = 0
    non_revenue_miles = 0
    deadhead_to_garage = 0
    passenger_miles = 0

    #NTD related
    ntd_revenue_miles = 0
    ntd_passenger_miles = 0
    ntd_deadhead_miles = 0
    is_first_leg_ntd = itins.first.trip.try(:ntd_reportable?)
    is_last_leg_ntd = itins.last.trip.try(:ntd_reportable?)

    from_address = @run.from_garage_address || @run.vehicle.try(:garage_address)
    to_address = itins.first.address

    time = @run.scheduled_start_time
    
    deadhead_from_garage = get_drive_distance(from_address, to_address, time)

    itins.each_with_index do |itin, index|
      next if index < 1

      from_address = itins[index - 1].address
      to_address = itin.address
      time = itin.time

      dist = get_drive_distance(from_address, to_address, time)
      if itin.capacity.to_f > 0
        revenuse_miles += dist 
        passenger_miles += dist * itin.capacity.to_f
      else
        non_revenue_miles += dist
      end    

      if itin.ntd_capacity.to_f > 0 || itin.trip.try(:ntd_reportable?)  
        ntd_revenue_miles += dist
      end

      if itin.ntd_capacity.to_f > 0 
        ntd_passenger_miles += dist * itin.ntd_capacity.to_f
      end
    end

    last_stop = itins.last
    from_address = last_stop.address
    to_address = @run.to_garage_address || @run.vehicle.try(:garage_address)
    time = last_stop.time
    deadhead_to_garage = get_drive_distance(from_address, to_address, time)

    total_dist = deadhead_from_garage + revenuse_miles + non_revenue_miles + deadhead_to_garage

    run_distance = @run.run_distance || RunDistance.new(run: @run)
    run_distance.total_dist = total_dist
    run_distance.revenue_miles = revenuse_miles
    run_distance.non_revenue_miles = non_revenue_miles
    run_distance.deadhead_from_garage = deadhead_from_garage
    run_distance.deadhead_to_garage = deadhead_to_garage
    run_distance.passenger_miles = passenger_miles
    #NTD
    ntd_deadhead_miles += deadhead_from_garage if is_first_leg_ntd 
    ntd_deadhead_miles += deadhead_to_garage if is_last_leg_ntd 
    ntd_total = ntd_revenue_miles + ntd_deadhead_miles

    run_distance.ntd_total_miles = ntd_total
    run_distance.ntd_total_revenue_miles = ntd_revenue_miles
    run_distance.ntd_total_passenger_miles = ntd_passenger_miles

    total_odometer_diff = @run.end_odometer - @run.start_odometer
    ntd_mileage_ratio = ntd_total / total_odometer_diff.to_f
    ntd_revenue_ratio = (ntd_total.to_f > 0) ? (ntd_revenue_miles / ntd_total.to_f) : 0

    run_distance.ntd_total_hours = @run.duration_in_hours * ntd_mileage_ratio #preportional to distance %
    run_distance.ntd_total_revenue_hours = run_distance.ntd_total_hours * ntd_revenue_ratio

    run_distance.save
  end

  # calculate ETA for each itinerary
  def process_eta
    return unless @run

    itins = @run.sorted_itineraries

    return if itins.empty?

    unless itins.first.is_begin_run?
      run_begin_itin = @run.build_begin_run_itinerary
      run_begin_itin.save
      itins.insert(0, run_begin_itin)  
    end
    unless itins.last.is_end_run? 
      puts "adding end begin itin"
      run_end_itin = @run.build_end_run_itinerary
      run_end_itin.save
      itins << run_end_itin
    end

    # make sure run_begin & run_end address valid
    run_begin_itin = itins.first
    if run_begin_itin.address.nil?
      run_begin_itin.address = @run.from_garage_address || @run.vehicle.try(:garage_address)
      run_begin_itin.save(validate: false)
    end
    run_end_itin = itins.last
    if run_end_itin.address.nil?
      run_end_itin.address = @run.to_garage_address || @run.vehicle.try(:garage_address)
      run_end_itin.save(validate: false)
    end

    eta_info = {}
    itin_count = itins.size
    itins.each_with_index do |itin, index|
      next if itin.arrival_time
      
      if index < (itin_count - 1)
        itin.next = itins[index + 1]
      end

      if index > 0
        itin.prev = itins[index - 1]    
      end  

      if index < (itin_count - 1)
        itin.calculate_travel_time! 
      end
      
      itin.calculate_eta! 

      eta_info[itin.itin_id] = {
        scheduled_time: itin.time,
        eta: itin.eta,
        wait_time: itin.wait_time,
        process_time: itin.process_time,
        depart_time: itin.depart_time,
        travel_time: itin.travel_time    
      }
    end

    eta_info
  end

  def append_capacity_to_itineraries(itins = [])
    # calculate occupancy
    occupancy = 0
    delta = 0
    ntd_occupancy = 0
    ntd_delta = 0
    itins.each do |itin|
      occupancy += delta
      itin.capacity = occupancy
      ntd_occupancy += ntd_delta
      itin.ntd_capacity = ntd_occupancy

      trip = itin.trip
      next unless trip

      if TripResult::NON_DISPATCHABLE_CODES.include?(trip.try(:trip_result).try(:code))
        delta = 0
        ntd_delta = 0
      elsif itin.leg_flag == 1 
        delta = trip.human_trip_size 
        ntd_delta = delta if trip.ntd_reportable?
      elsif itin.leg_flag == 2
        delta = -1 * trip.human_trip_size
        ntd_delta = delta if trip.ntd_reportable?
      end
    end

    itins
  end

  def get_drive_distance(from_addr, to_addr, time = DateTime.now)
    calculator = get_dist_duration_calculator(from_addr, to_addr, time)
    calculator.get_drive_distance.to_f
  end

  def get_drive_duration(from_addr, to_addr, time = DateTime.now)
    calculator = get_dist_duration_calculator(from_addr, to_addr, time)
    calculator.get_drive_time.to_f
  end

  def get_dist_duration_calculator(from_addr, to_addr, time = DateTime.now)
    from_lat = from_addr.try(:latitude)
    from_lon = from_addr.try(:longitude)
    to_lat = to_addr.try(:latitude)
    to_lon = to_addr.try(:longitude)

    params = {
      from_lat: from_lat, 
      from_lon: from_lon, 
      to_lat: to_lat, 
      to_lon: to_lon, 
      trip_datetime: time
    }
    
    TripDistanceDurationProxy.new(ENV['TRIP_PLANNER_TYPE'], params)
  end

  def time_portion(time)
    (time - time.beginning_of_day) if time
  end
end
