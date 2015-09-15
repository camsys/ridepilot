class TripsController < ApplicationController
  load_and_authorize_resource :except=>[:show]

  def index
    Date.beginning_of_week= :sunday

    @trips = Trip.for_provider(current_provider_id).includes(:customer, :pickup_address, {:run => [:driver, :vehicle]})
    .references(:customer, :pickup_address, {:run => [:driver, :vehicle]}).order(:pickup_time)
    filter_trips
    
    @vehicles        = add_cab(Vehicle.where(:provider_id => current_provider_id))
    @drivers         = Driver.for_provider current_provider_id
    @start_pickup_date = Time.at(session[:start].to_i).to_date
    @end_pickup_date = Time.at(session[:end].to_i).to_date
    @days_of_week = trip_sessions[:days_of_week].blank? ? [0,1,2,3,4,5,6] : trip_sessions[:days_of_week].split(',').map(&:to_i)

    @trips_json = @trips.has_scheduled_time.map(&:as_calendar_json).to_json # TODO: sql refactor to improve performance
    @day_resources = []

    if @start_pickup_date > @end_pickup_date
      flash.now[:alert] = TranslationEngine.translate_text(:from_date_cannot_later_than_to_date)
    else
      flash.now[:alert] = nil
      @day_resources = (@start_pickup_date..@end_pickup_date).select{|d| @days_of_week.index(d.wday)}.map{|d| {
        id:   d.to_s(:js), 
        name: d.strftime("%a, %b %d,%Y"),
        isDate: true
        } }.to_json
    end

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @trips }
      format.json { render :json => @trips }
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
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @trip }
      format.js   { @remote = true; render :json => {:form => render_to_string(:partial => 'form') }, :content_type => "text/json" }
    end
  end

  def edit
    prep_view
    
    respond_to do |format|
      format.html 
      format.js  { @remote = true; render :json => {:form => render_to_string(:partial => 'form')}, :content_type => "text/json" }
    end
  end

  def show
    @trip = Trip.find(params[:id])
    prep_view

    authorize! :show, @trip if !@trip.customer.authorized_for_provider(current_provider.id)
    
    respond_to do |format|
      format.html 
      format.js  { @remote = true; render :json => {:form => render_to_string(:partial => 'form')}, :content_type => "text/json" }
    end
  end

  def create
    if params[:trip][:customer_id] && customer = Customer.find_by_id(params[:trip][:customer_id])
      #authorize! :read, customer
      params[:trip][:provider_id] = customer.provider.id if customer.provider.present?
    else
      params[:trip][:customer_id] = ""
    end    
    handle_trip_params params[:trip]
    @trip = Trip.new(trip_params)
    authorize! :manage, @trip
    
    respond_to do |format|
      prep_view
      if @trip.is_all_valid?(current_provider_id) && @trip.save
        format.html {
          if params[:run_id].present?
            redirect_to(edit_run_path(@trip.run), :notice => 'Trip was successfully created.')       
          else
            redirect_to(trips_path, :notice => 'Trip was successfully created.') 
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
      if @trip.is_all_valid?(current_provider_id) && @trip.update_attributes(trip_params)
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
      :cab,
      :service_level_id,
      :trip_purpose_id,
      :trip_result_id,
      :vehicle_id,
      customer_attributes: [:id]
    )
  end

  def prep_view
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
    filters_hash = params[:trip_filters] || {}
    
    update_sessions(filters_hash)

    trip_filter = TripFilter.new(@trips, trip_sessions)
    @trips = trip_filter.filter!
    # need to re-update start&end pickup filters
    # as default values are used if they were not presented initially
    update_sessions({
      start: trip_filter.filters[:start],
      end: trip_filter.filters[:end],
      days_of_week: trip_filter.filters[:days_of_week]
      })
  end

  def update_sessions(params = {})
    params.each do |key, val|
      session[key] = val if !val.nil?
    end
  end

  def trip_sessions
    {
      start: session[:start],
      end: session[:end], 
      driver_id: session[:driver_id], 
      vehicle_id: session[:vehicle_id],
      trip_result_id: session[:trip_result_id], 
      status_id: session[:status_id],
      days_of_week: session[:days_of_week]
    }
  end

  def add_cab(vehicles)
    cab_vehicle = Vehicle.new :name => "Cab"
    cab_vehicle.id = -1
    [cab_vehicle] + vehicles 
  end
end
