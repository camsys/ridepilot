# a note on general run workflow:
# Runs are created as part of the trip scheduling 
# process; they're associated with a vehicle and
# a driver.  At the end of the day, the driver
# must update the run with post-run data like
# odometer start/end and no-shows.  That is 
# presented by my_runs and end_of_day

class RunsController < ApplicationController
  load_and_authorize_resource
  before_filter :filter_runs, :only => :index

  def index
    @runs = @runs.for_provider(current_provider_id)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @trips }
      format.js {
        rows = if @runs.present?
          @runs.map do |r|
            render_to_string :partial => "row.html", :locals => { :run => r }
          end 
        else 
          [render_to_string( :partial => "no_runs.html" )]
        end

        render :json => { :rows => rows }
      }
    end
  end

  def new
    @run = Run.new
    @run.provider_id = current_provider_id
    setup_run
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @trip }
    end
  end

  def uncompleted_runs
    @runs = Run.for_provider(current_provider_id).where("complete = false").order("date desc")
    render "index"
  end

  def edit
    setup_run
    @trip_results = TRIP_RESULT_CODES.map { |k,v| [v,k] }
  end

  def create
    authorize! :manage, current_provider
 
    @run = Run.new(run_params)
    @run.provider = current_provider
    
    respond_to do |format|
      if @run.save
        format.html { redirect_to(runs_path(date_range(@run)), :notice => 'Run was successfully created.') }
        format.xml  { render :xml => @run, :status => :created, :location => @run }
      else
        setup_run

        format.html { render :action => "new" }
        format.xml  { render :xml => @run.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    authorize! :manage, current_provider
    
    # Massage trip_attributes. We're not using a nested form so that we can use
    # the partial for AJAX requests, and as a result we need to reset the keys
    # in the trips_attributes hash and add the trip id.
    corrected_trip_attributes = {}
    if params[:trips_attributes].is_a? Hash
      params[:trips_attributes].each do |key, values|
        corrected_trip_attributes[corrected_trip_attributes.size.to_s] = values.merge({"id" => key})
      end
      params[:run][:trips_attributes] = corrected_trip_attributes
    end
                
    respond_to do |format|
      if @run.update_attributes(run_params)
        format.html { redirect_to(runs_path(date_range(@run)), :notice => 'Run was successfully updated.') }
        format.xml  { head :ok }
      else
        setup_run
        @trip_results = TRIP_RESULT_CODES.map { |k,v| [v,k] }
        
        format.html { render :action => "edit" }
        format.xml  { render :xml => @run.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @run.destroy

    respond_to do |format|
      format.html { redirect_to(runs_path(date_range(@run)), :notice => 'Run was successfully deleted.') }
      format.xml  { head :ok }
    end
  end
  
  def for_date
    date = Date.parse params[:date]
    @runs = @runs.for_provider(current_provider_id).incomplete_on date
    cab_run = Run.new :cab => true
    cab_run.id = -1
    @runs = @runs + [cab_run] 
    render :json =>  @runs.to_json 
  end
  
  private
  
  def setup_run
    @drivers = Driver.where(:provider_id=>@run.provider_id)
    @vehicles = Vehicle.active.where(:provider_id=>@run.provider_id)
  end
  
  def filter_runs
    if params[:end].present? && params[:start].present?
      @week_start = Time.at params[:start].to_i
      @week_end   = Time.at params[:end].to_i
    else
      time     = Time.now
      @week_start = time.beginning_of_week
      @week_end   = @week_start + 6.days
    end
    
    @runs = @runs.
      where("date >= '#{@week_start.to_s(:db)}'").
      where("date < '#{@week_end.to_s(:db)}'")
  end

  def date_range(run)
    if run.date
      week_start = run.date.beginning_of_week
      {:start => week_start.to_time.to_i, :end => (week_start + 6.days).to_time.to_i } 
    end    
  end
  
  def run_params
    params.require(:run).permit(:name, :date, :start_odometer, :end_odometer, :scheduled_start_time, :scheduled_end_time, :unpaid_driver_break_time, :vehicle_id, :driver_id, :paid, :complete, :actual_start_time, :actual_end_time, :trips_attributes => [
      :id,
      :appointment_time,
      :attendant_count,
      :customer_id,
      :customer_informed,
      :donation,
      :driver_id,
      :dropoff_address_id,
      :funding_source_id,
      :group_size,
      :guest_count,
      :medicaid_eligible,
      :mileage,
      :mobility_id,
      :notes,
      :pickup_address_id,
      :pickup_time,
      :repeats_fridays,
      :repeats_mondays,
      :repeats_thursdays,
      :repeats_tuesdays,
      :repeats_wednesdays,
      :repetition_customer_informed,
      :repetition_driver_id,
      :repetition_interval,
      :repetition_vehicle_id,
      :round_trip,
      :run_id,
      :service_level,
      :trip_purpose,
      :trip_result,
      :vehicle_id,
      customer_attributes: [:id]
    ])
  end
end
