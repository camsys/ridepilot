class RecurringDispatchersController < ApplicationController
  before_action :authorization, :set_day_of_week

  def index
    Date.beginning_of_week= :sunday
    
    query_trips_runs

    respond_to do |format|
      format.html
    end
  end

  def schedule
    @run = RepeatingRun.find_by_id params[:run_id]
    @prev_run = RepeatingRun.find_by_id(params[:prev_run_id]) if params[:prev_run_id].present?
    if @run
      @scheduler = RecurringTripScheduler.new(params[:trip_id], params[:run_id], @day_of_week)
      @scheduler.execute

      trip = RepeatingTrip.find_by_id params[:trip_id]
      #if @prev_run
        #TrackerActionLog.trips_removed_from_run(@prev_run, [trip], current_user, RepeatingRun::DAYS_OF_WEEK[@day_of_week])
      #end

      #TrackerActionLog.trips_added_to_run(@run, [trip], current_user, RepeatingRun::DAYS_OF_WEEK[@day_of_week])

      query_trips_runs
    end
  end

  def schedule_multiple
    @target_trip_ids = params[:trip_ids].split(',') if params[:trip_ids].present?
  
    if @target_trip_ids && @target_trip_ids.any?
      @new_status_id = params[:status_id].to_i if params[:status_id]

      @errors = []
      assigned_trip_ids = []
      @error_trip_count = 0
      @target_trip_ids.each do |trip_id|
        scheduler = RecurringTripScheduler.new(trip_id, @new_status_id, @day_of_week)
        scheduler.execute
        
        if scheduler.errors.any?
          @error_trip_count += 1
          @errors += scheduler.errors
        else
          assigned_trip_ids << trip_id
        end
      end

      @target_run = RepeatingRun.find_by_id @new_status_id
      #if @target_run
        #TrackerActionLog.trips_added_to_run(@target_run, RepeatingTrip.where(id: assigned_trip_ids), current_user, RepeatingRun::DAYS_OF_WEEK[@day_of_week])
      #end

      @errors.uniq!

      query_trips_runs
    end
  end

  def unschedule
    @prev_run = RepeatingRun.find_by_id(params[:prev_run_id])
    @target_trip_ids = params[:trip_ids].split(',')
    if @target_trip_ids.any?
      @new_status_id = params[:run_id].to_i if params[:run_id]

      if @prev_run
        @prev_run.weekday_assignments.for_wday(@day_of_week).where(repeating_trip_id: @target_trip_ids).delete_all
        #TrackerActionLog.trips_removed_from_run(@prev_run, RepeatingTrip.where(id: @target_trip_ids), current_user, RepeatingRun::DAYS_OF_WEEK[@day_of_week])
      end

      query_trips_runs
    end
  end

  def run_trips
    @run = RepeatingRun.find_by_id params[:run_id]
  end

  def cancel_run
    @run = RepeatingRun.find_by_id params[:run_id]
    if @run && @run.weekday_assignments.for_wday(@day_of_week).any?
      @run.weekday_assignments.for_wday(@day_of_week).delete_all
      @run.repeating_run_manifest_orders.for_wday(@day_of_week).delete_all
      TrackerActionLog.cancel_run(@run, current_user, RepeatingRun::DAYS_OF_WEEK[@day_of_week])
    end


    query_trips_runs
  end

  def update_run_manifest_order
    @run = RepeatingRun.find_by_id params[:run_id]

    if @run && params[:manifest_order].present?
      new_order = params[:manifest_order].split(',').uniq
      manifest_order = @run.repeating_run_manifest_orders.for_wday(@day_of_week).first || @run.repeating_run_manifest_orders.build(wday: @day_of_week)
      manifest_order.manifest_order = new_order 
      manifest_order.save(validate: false)

      #TrackerActionLog.rearrange_trip_itineraries(@run, current_user, RepeatingRun::DAYS_OF_WEEK[@day_of_week])
    end
  end

  def batch_update_daily_dispatch_action
    @run = RepeatingRun.find_by_id params[:run_id]
    Run.repeating_based_on(@run).today_and_future.batch_update_recurring_trip_assignment!
  end
  
  private

  def authorization
    authorize! :read, RepeatingRun, :provider_id => current_provider_id
    authorize! :read, RepeatingTrip, :provider_id => current_provider_id
  end

  def query_trips_runs
    set_day_of_week
    run_ids = RepeatingRun.for_provider(current_provider_id).active
      .collect{|rr| rr.id if rr.try("repeats_#{RepeatingRun::DAYS_OF_WEEK[@day_of_week]}s")}
      .compact

    @runs = RepeatingRun.where(id: run_ids).reorder(nil).default_order

    trip_ids = RepeatingTrip.for_provider(current_provider_id).active
      .collect{|rr| rr.id if rr.try("repeats_#{RepeatingTrip::DAYS_OF_WEEK[@day_of_week]}s")}
      .compact
    total_trips = RepeatingTrip.where(id: trip_ids)
    @trips = total_trips
      .includes(:customer, :pickup_address)
      .references(:customer, :pickup_address)
      .order("repeating_trips.pickup_time::time")

    @scheduled_trips = total_trips.joins(:weekday_assignments).where(weekday_assignments: {wday: @day_of_week}).distinct

    @unscheduled_trips = @trips.where.not(id: @scheduled_trips.pluck(:id))
  end

  def set_day_of_week
    @day_of_week = if params[:day_of_week].present?
      params[:day_of_week].to_i
    elsif session[:recurring_day_of_week].present?
      session[:recurring_day_of_week].to_i
    else
      Date.today.wday
    end

    session[:recurring_day_of_week] = @day_of_week
  end
end