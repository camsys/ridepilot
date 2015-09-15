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
    filter_by_status!
    filter_by_result!

    @trips
  end

  private 

  def filter_by_pickup_time!
    utility = Utility.new
    t_start = utility.parse_datetime(@filters[:start]) 
    t_end = utility.parse_datetime(@filters[:end]) 

    if !t_start && !t_end
      time    = Time.now
      t_start = time.beginning_of_week.to_date.in_time_zone
      t_end   = t_start + 6.days
    elsif !t_end
      t_end   = t_start + 6.days
    elsif !t_start
      t_start   = t_end - 6.days
    end

    @trips = @trips.
      where("pickup_time >= '#{t_start.beginning_of_day.strftime "%Y-%m-%d %H:%M:%S"}'").
      where("pickup_time <= '#{t_end.end_of_day.strftime "%Y-%m-%d %H:%M:%S"}'").order(:pickup_time)
    
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

  def filter_by_status!
    if @filters[:status_id].present?  
      if @filters[:status_id].to_i == 1
        @trips = @trips.where("run_id is NOT NULL or cab = true")
      else
        @trips = @trips.where("run_id is NULL and cab = false")
      end
    end
  end

  def filter_by_result!
    if @filters[:trip_result_id].present?  
      @trips = @trips.where(trip_result_id: @filters[:trip_result_id]) 
    end
  end

end