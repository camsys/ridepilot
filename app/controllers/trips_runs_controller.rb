class TripsRunsController < ApplicationController
  before_action :authorization

  def index
    Date.beginning_of_week= :sunday

    filters_hash = runs_trips_params || {}
    update_sessions(filters_hash.except(:start, :end))
    
    @runs = Run.for_provider(current_provider_id).includes(:driver, :vehicle)
    filter_runs

    @trips = Trip.has_scheduled_time.for_provider(current_provider_id).includes(:customer, :pickup_address, {:run => [:driver, :vehicle]})
    .references(:customer, :pickup_address, {:run => [:driver, :vehicle]}).order(:pickup_time)
    filter_trips
    
    @vehicles        = add_cab(Vehicle.accessible_by(current_ability).where(:provider_id => current_provider_id))
    @drivers         = Driver.active.for_provider current_provider_id
    @run_trip_day    = Utility.new.parse_datetime(session[:run_trip_day])

    @runs_array       = add_unscheduled_run(add_cab_run(@runs)).map{ |run|
      as_resource_json(run)
    }.sort{|a,b| b[:id] <=> a[:id]}

    @runs_for_dropdown = @runs_array.collect {|r| [r[:label], r[:id]]}

    @runs_json = @runs_array.to_json # TODO: sql refactor to improve performance
    @trips_json = @trips.map(&:as_run_event_json).to_json # TODO: sql refactor to improve performance

    respond_to do |format|
      format.html
    end
  end

  def schedule
    respond_to do |format|
      format.js { render json: TripScheduler.new(params[:trip_id], params[:run_id]).execute }
    end
  end
  
  private

  def authorization
    authorize! :read, Run, :provider_id => current_provider_id
    authorize! :read, Trip, :provider_id => current_provider_id
  end

  def filter_trips
    trip_filter = TripFilter.new(@trips, trip_sessions)
    @trips = trip_filter.filter!

  end

  def filter_runs
    run_filter = RunFilter.new(@runs, run_sessions)
    @runs = run_filter.filter!
  end

  def runs_trips_params
    raw_params = params[:run_trip_filters] || {}
    if raw_params
      raw_params[:run_trip_day] = Date.today.in_time_zone.to_i if raw_params[:run_trip_day].blank?
      raw_params[:start] = raw_params[:run_trip_day]
      raw_params[:end] = raw_params[:run_trip_day]
    end

    raw_params
  end

  def update_sessions(params = {})
    params.each do |key, val|
      session[key] = val if !val.nil?
    end
  end

  def run_sessions
    {
      start: session[:run_trip_day],
      end: session[:run_trip_day], 
      driver_id: session[:driver_id], 
      vehicle_id: session[:vehicle_id],
      run_result_id: session[:run_result_id]
    }
  end

  def trip_sessions
    {
      start: session[:run_trip_day],
      end: session[:run_trip_day], 
      driver_id: session[:driver_id], 
      vehicle_id: session[:vehicle_id],
      trip_result_id: session[:trip_result_id], 
      status_id: session[:status_id]
    }
  end

  def add_cab(vehicles)
    cab_vehicle = Vehicle.new :name => TranslationEngine.translate_text(:cab)
    cab_vehicle.id = -1
    [cab_vehicle] + vehicles 
  end

  def add_cab_run(runs)
    [Run.fake_cab_run] + runs 
  end

  def add_unscheduled_run(runs)
    [Run.fake_unscheduled_run] + runs 
  end

  def as_resource_json(run)
    if run.id && run.id >= 0 
      name = "<input type='radio' name='run_records' value=#{run.id}></input>&nbsp;<a href='#{runs_path}/#{run.id}'>#{run.label}</a>"
    else
      name = "<input type='radio' name='run_records' value=#{run.id}></input>&nbsp;#{run.label}"
    end

    {
      id:   run.id, 
      label: run.label,
      isDate: false,
      name: name
    }
  end
end
