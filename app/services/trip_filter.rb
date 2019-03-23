class TripFilter 

  attr_reader :trips, :filters

  def initialize(trips, filters = {})
    @trips = trips
    @filters = filters
  end

  def filter!
    filter_by_pickup_time!
    filter_by_days_of_week!
    filter_by_vehicle!
    filter_by_driver!
    filter_by_customer!
    filter_by_run!
    filter_by_status!
    filter_by_funding_source!
    filter_by_result!

    @trips
  end

  private 

  def filter_by_pickup_time!
    utility = Utility.new
    t_start = utility.parse_date(@filters[:start]) 
    t_end = utility.parse_date(@filters[:end]) 
    
    if !t_start && !t_end
      time    = Time.current
      t_start = time.to_date.in_time_zone
      t_end   = t_start
    elsif !t_end
      t_end   = t_start
    elsif !t_start
      t_start   = t_end
    end
    
    @trips = @trips.
      where("pickup_time >= '#{t_start.beginning_of_day.utc.strftime "%Y-%m-%d %H:%M:%S"}'").
      where("pickup_time <= '#{t_end.end_of_day.utc.strftime "%Y-%m-%d %H:%M:%S"}'").order(:pickup_time)
    
    @filters[:start] = t_start.to_i
    @filters[:end] = t_end.to_i
  end

  def filter_by_days_of_week!
    days_of_week = @filters[:days_of_week].blank? ? "0,1,2,3,4,5,6" : @filters[:days_of_week]
    @trips = @trips.where('extract(dow from pickup_time) in (?)', days_of_week.split(','))
    @filters[:days_of_week] = days_of_week
  end

  def filter_by_vehicle!
    if @filters[:vehicle_id].present?  
      if @filters[:vehicle_id].to_i == -1
        @trips = @trips.where(cab: true)
      else
        @trips = @trips.includes(run: :vehicle).references(run: :vehicle).where("runs.vehicle_id": @filters[:vehicle_id]) 
      end
    end
  end

  def filter_by_driver!
    if @filters[:driver_id].present?  
      @trips = @trips.includes(run: :driver).references(run: :driver).where("runs.driver_id": @filters[:driver_id]) 
    end
  end

  def filter_by_customer!
    if @filters[:customer_id].present?  
      @trips = @trips.where("trips.customer_id": @filters[:customer_id]) 
    end
  end

  def filter_by_run!
    unless @filters[:run_id].blank?  
      @trips = @trips.includes(:run).references(:run).where("runs.id": @filters[:run_id]) 
    end
  end

  def filter_by_status!
    if @filters[:status_id].present?  
      status_id = @filters[:status_id].to_i
      if status_id == -2
        # unscheduled
        @trips = @trips.where("run_id is NULL and cab = false")
      elsif status_id == -1
        # CAB
        @trips = @trips.where("run_id is NULL and cab = ?", true)
      elsif status_id >= 0
        # Run
        @trips = @trips.where(run_id: status_id)
      end
    end
  end

  def filter_by_result!
    if @filters[:trip_result_id].present?
      trip_result_ids = @filters[:trip_result_id].dup

      # Replace the hard-coded ID for unscheduled trips with `nil`
      if trip_result_ids.include?(TripResult::UNSCHEDULED_ID)
        trip_result_ids[trip_result_ids.index(TripResult::UNSCHEDULED_ID)] = nil
      elsif trip_result_ids.include?(TripResult::UNSCHEDULED_ID.to_s)
        trip_result_ids[trip_result_ids.index(TripResult::UNSCHEDULED_ID.to_s)] = nil
      end

      @trips = @trips.where(trip_result_id: trip_result_ids) 
    end
  end

  def filter_by_funding_source!
    if @filters[:funding_source_id].present?
      funding_source_ids = @filters[:funding_source_id].dup

      if funding_source_ids.include?(FundingSource::SHOW_ALL_ID)
        funding_source_ids[funding_source_ids.index(FundingSource::SHOW_ALL_ID)] = nil
      elsif funding_source_ids.include?(FundingSource::SHOW_ALL_ID.to_s)
        funding_source_ids[funding_source_ids.index(FundingSource::SHOW_ALL_ID.to_s)] = nil
      end

      @trips = @trips.where(funding_source_id: funding_source_ids) 
    end
  end

end