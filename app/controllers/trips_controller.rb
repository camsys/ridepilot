class TripsController < ApplicationController
  load_and_authorize_resource
  
  before_filter :set_calendar_week_start, :only => [:index, :new, :edit]

  def index
    @trips = @trips.for_provider(current_provider_id).includes(:customer, {:run => [:driver, :vehicle]}).order(:pickup_time)
    
    respond_to do |format|
      format.html do
        @start = params[:start].to_i
        # let js handle grabbing the trips
        @trips = [] 
        @vehicles = add_cab(Vehicle.accessible_by(current_ability).where(:provider_id => current_provider_id))
      end
      format.xml  { render :xml => @trips }
      format.json { render :json => trips_json }
    end
  end

  def trips_requiring_callback
    #The trip coordinator has made decisions on whether to confirm or
    #turn down trips.  Now they want to call back the customer to tell
    #them what's happened.  This is a list of all customers who have
    #not been marked as informed, ordered by when they were last
    #called.

    @trips = Trip.accessible_by(current_ability).for_provider(current_provider_id).where(
      "customer_informed = false AND pickup_time >= ?", Date.today.in_time_zone.utc).order("called_back_at")

    respond_to do |format|
      format.html
      format.xml  { render :xml => @trips }
    end
  end

  def unscheduled
    #The trip coordinatior wants to confirm or turn down individual
    #trips.  This is a list of all trips that haven't been decided
    #on yet.

    @trips = Trip.accessible_by(current_ability).for_provider(current_provider_id).where(
      ["trip_result_id is NULL and pickup_time >= ? ", Date.today]).order("pickup_time")
  end

  def reconcile_cab
    #the cab company has sent a log of all trips in the past [time period]
    #we want to mark some trips as no-shows.  This will be a paginated
    #list of trips
    @trips = Trip.accessible_by(current_ability).for_provider(current_provider_id).includes(:trip_result).references(:trip_result).where(
      "cab = true and (trip_results.code = 'COMP' or trip_results.code = 'NS')").reorder("pickup_time desc").paginate :page=>params[:page], :per_page=>50
  end

  def no_show
    @trip = Trip.find(params[:trip_id])
    if can? :edit, @trip
      @trip.trip_result = TripResult.find_by(code: 'NS')
      @trip.save
    end
    redirect_to :action=>:reconcile_cab, :page=>params[:page]
  end

  def send_to_cab
    @trip = Trip.find(params[:trip_id])
    if can? :edit, @trip
      @trip.cab = true
      @trip.cab_notified = false
      @trip.trip_result = TripResult.find_by(code: 'COMP')
      @trip.save
    end
    redirect_to :action=>:reconcile_cab, :page=>params[:page]
  end

  def reached
    #mark the user as having been informed that their trip has been
    #approved or turned down
    @trip = Trip.find(params[:trip_id])
    if can? :edit, @trip
      @trip.called_back_at = Time.now
      @trip.called_back_by = current_user
      @trip.customer_informed = true
      @trip.save
    end
    redirect_to :action=>:trips_requiring_callback
  end

  def confirm
    @trip = Trip.find(params[:trip_id])
    if can? :edit, @trip
      @trip.trip_result = TripResult.find_by(code: 'COMP')
      @trip.save
    end
    redirect_to :action=>:unscheduled
  end

  def turndown
    @trip = Trip.find(params[:trip_id])
    if can? :edit, @trip
      @trip.trip_result = TripResult.find_by(code: 'TD')
      @trip.save
    end
    redirect_to :action=>:unscheduled
  end

  def new
    @trip = Trip.new(:provider_id => current_provider_id)

    if params[:run_id] && run = Run.find_by_id(params[:run_id])
      d = run.date
      t = run.scheduled_start_time || (d.at_midnight + 12.hours)
      @trip.run_id = run.id
      @trip.pickup_time = Time.zone.local(d.year, d.month, d.day, t.hour, t.min, 0)
      @trip.appointment_time = @trip.pickup_time + 30.minutes
    end

    if params[:customer_id] && customer = Customer.find_by_id(params[:customer_id])
      @trip.customer_id = customer.id
      @trip.pickup_address_id = customer.address_id
      @trip.mobility_id = customer.mobility_id 
      @trip.funding_source_id = customer.default_funding_source_id
      @trip.service_level = customer.service_level
    end

    prep_view
    @trips = []
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @trip }
      format.js   { @remote = true; render :json => {:form => render_to_string(:partial => 'form') }, :content_type => "text/json" }
    end
  end

  def edit
    prep_view
    @trips = []
    
    respond_to do |format|
      format.html 
      format.js  { @remote = true; render :json => {:form => render_to_string(:partial => 'form')}, :content_type => "text/json" }
    end
  end

  def create
    if params[:trip][:customer_id] && customer = Customer.find_by_id(params[:trip][:customer_id])
      authorize! :read, customer
      params[:trip][:provider_id] = customer.provider.id if customer.provider.present?
    else
      params[:trip][:customer_id] = ""
    end    
    handle_trip_params params[:trip]
    @trip = Trip.new(trip_params)
    authorize! :manage, @trip
    
    respond_to do |format|
      prep_view
      if @trip.save
        format.html {
          if params[:run_id].present?
            redirect_to(edit_run_path(@trip.run), :notice => 'Trip was successfully created.')       
          else
            redirect_to(trips_path(:start => @trip.pickup_time.to_i), :notice => 'Trip was successfully created.') 
          end
        }
        format.js { render :json => {:status => "success", :trip => render_to_string(:partial => 'runs/trip', :locals => {:trip => @trip})}, :content_type => "text/json" }
      else
        format.html { render :action => "new" }
        format.js   { @remote = true; render :json => {:status => "error", :form => render_to_string(:partial => 'form')}, :content_type => "text/json" }
      end
    end

  end

  def update
    if params[:trip][:customer_id] && customer = Customer.find_by_id(params[:trip][:customer_id])
      authorize! :read, customer
      params[:trip][:provider_id] = customer.provider.id if customer.provider.present?
    else
      params[:trip][:customer_id] = @trip.customer_id
    end    
    handle_trip_params params[:trip]
    authorize! :manage, @trip

    respond_to do |format|
      if @trip.update_attributes(trip_params)
        format.html { redirect_to(trips_path, :notice => 'Trip was successfully updated.')  }
        format.js { 
          render :json => {:status => "success"}, :content_type => "text/json"
        }
      else
        prep_view
        format.html { render :action => "edit"  }
        format.js   { @remote = true; render :json => {:status => "error", :form => render_to_string(:partial => 'form') }, :content_type => "text/json" }
      end
    end
  end

  def destroy
    @trip = Trip.find(params[:id])
    @trip.destroy

    respond_to do |format|
      format.html { redirect_to(trips_url) }
      format.xml  { head :ok }
      format.js   { render :json => {:status => "success"}, :content_type => "text/json" }
    end
  end

  private
  
  def trip_params
    params.require(:trip).permit(
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
      :provider_id, # We normally wouldn't accept this and would set it manually on the instance, but in this controller we're setting it in the params dynamically
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
      :service_level_id,
      :trip_purpose_id,
      :trip_result_id,
      :vehicle_id,
      customer_attributes: [:id]
    )
  end
  
  def set_calendar_week_start
    @week_start = if params[:start].present?
      Time.at params[:start].to_i/1000
    elsif @trip.try :pickup_time
      @trip.pickup_time.beginning_of_week
    else
      Time.now.beginning_of_week
    end
  end
  
  def trips_json
    filter_trips
    trips = @trips.map { |trip| 
      { :id    => trip.id,
        :start => trip.pickup_time.to_s(:js),
        :end   => trip.appointment_time.to_s(:js),
        :title => trip.customer.name
      }
    }

    days = @trips.group_by(&:date)
    rows = []
    days.each do |day, trips|
      rows << render_to_string(:partial => "day_row.html", :locals => { :day => day })
      trips.each do |trip|
        rows << render_to_string(:partial => "trip_row.html", :locals => { :trip => trip })
      end
    end

    {:events => trips, :rows => rows }    
  end

  def prep_view
    authorize! :read, @trip
    @customer           = @trip.customer
    @mobilities         = Mobility.order(:name).all
    @funding_sources    = FundingSource.by_provider(current_provider)
    @trip_results       = TripResult.pluck(:name, :id)
    @trip_purposes      = TripPurpose.all
    @drivers            = Driver.active.for_provider @trip.provider_id
    @trips              = [] if @trips.nil?
    @vehicles           = add_cab(Vehicle.active.for_provider(@trip.provider_id))
    @repeating_vehicles = @vehicles 
    @service_levels     = ServiceLevel.pluck(:name, :id)

    @trip.run_id = -1 if @trip.cab

    cab_run = Run.new :cab => true
    cab_run.id = -1
    @runs = Run.for_provider(@trip.provider_id).incomplete_on(@trip.pickup_time.try(:to_date)) << cab_run
  end
  
  def handle_trip_params(trip_params)
    if trip_params[:run_id] == '-1' 
      #cab trip
      trip_params[:run_id] = nil
      trip_params[:cab] = true
    else
      trip_params[:cab] = false
    end

    if trip_params[:customer_informed] and not @trip.customer_informed
      trip_params[:called_back_by] = current_user
      trip_params[:called_back_at] = DateTime.now.to_s
    end
  end

  def filter_trips
    if params[:end].present? && params[:start].present?
      t_start = Time.at(params[:start].to_i).to_date.in_time_zone.utc
      t_end   = Time.at(params[:end].to_i).to_date.in_time_zone.utc
    else
      time    = Time.now
      t_start = time.beginning_of_week.to_date.in_time_zone.utc
      t_end   = t_start + 6.days
    end

    @trips = @trips.
      where("pickup_time >= '#{t_start.strftime "%Y-%m-%d %H:%M:%S"}'").
      where("pickup_time <= '#{t_end.strftime "%Y-%m-%d %H:%M:%S"}'").order(:pickup_time)
      
    if params[:vehicle_id].present?  
      if params[:vehicle_id].to_i == -1
        @trips = @trips.select {|t| t.cab } 
      else
        @trips = @trips.select {|t| t.vehicle_id == params[:vehicle_id].to_i } 
      end
    end
  end

  def add_cab(vehicles)
    cab_vehicle = Vehicle.new :name => "Cab"
    cab_vehicle.id = -1
    [cab_vehicle] + vehicles 
  end
end
