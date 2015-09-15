class TripScheduler
  attr_reader :trip, :run

  def initialize(trip_id, run_id)
    @trip = Trip.find_by_id(trip_id)
    @run = get_run(run_id.to_i)
  end

  def execute
    return response_as_json(false) if !@trip || !@run 
    return response_as_json(true) if @trip.adjusted_run_id == @run.id

    case @run.id
    when Run::UNSCHEDULED_RUN_ID
      unschedule
    when Run::CAB_RUN_ID 
      schedule_to_cab
    else
      schedule_to_run
    end
  end

  private

  def get_run(run_id)
    case run_id
    when Run::CAB_RUN_ID 
      Run.fake_cab_run
    when Run::UNSCHEDULED_RUN_ID
      Run.fake_unscheduled_run
    else
      Run.find_by_id(run_id)
    end
  end

  def unschedule
    @trip.cab = false
    @trip.run = nil
    response_as_json @trip.save, @trip.errors.full_messages.join(';')
  end

  def schedule_to_cab
    @trip.cab = true
    @trip.run = nil
    response_as_json @trip.save, @trip.errors.full_messages.join(';')
  end

  def schedule_to_run
    if !validate_time_availability
      response_as_json false, TranslationEngine.translate_text(:not_fit_in_run_schedule)
    elsif !validate_vehicle_availability 
      response_as_json false, TranslationEngine.translate_text(:vehicle_unavailable)
    elsif !validate_driver_availability 
      response_as_json false, TranslationEngine.translate_text(:driver_unavailable)
    else
      @trip.cab = false
      @trip.run = @run
      response_as_json @trip.save, @trip.errors.full_messages.join(';')
    end
  end

  # run avaiability validations

  # run can hold a trip
  def validate_time_availability
    run_start_time = @run.scheduled_start_time
    run_end_time = @run.scheduled_end_time

    if run_start_time && run_end_time
      @trip.pickup_time >= @run.scheduled_start_time && @trip.appointment_time <= @run.scheduled_end_time
    else
      true
    end
  end

  def validate_vehicle_availability
    # TODO: revisit after vehicle capacity is added
    @run.vehicle && @run.vehicle.active
  end

  def validate_driver_availability
    trip_pickup_time = @trip.pickup_time
    @run.driver ?  @run.driver.active && @run.driver.available?(trip_pickup_time.wday, trip_pickup_time.strftime('%H:%M')) : true
  end

  def response_as_json(is_success, error_text = '')
    {
      success: is_success,
      message: error_text || '',
      trip_event_json: is_success ? @trip.as_run_event_json : nil
    }
  end

end