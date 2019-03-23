class TripsController < ApplicationController
  load_and_authorize_resource :except=>[:show]

  def index
    Date.beginning_of_week= :sunday

    # by default, select all trip results
    unless session[:trips_trip_result_id].present?
      session[:trips_trip_result_id] = [TripResult::UNSCHEDULED_ID, TripResult::SHOW_ALL_ID] + TripResult.pluck(:id).uniq
    end
    
    unless session[:trips_funding_source_id].present?
      session[:trips_funding_source_id] = [FundingSource::SHOW_ALL_ID] + FundingSource.by_provider(current_provider).pluck(:id).uniq
    end

    filter_trips

    @vehicles        = Vehicle.where(:provider_id => current_provider_id)
    cab_enabled = current_provider.try(:cab_enabled?)

    @vehicles = add_cab(@vehicles) if cab_enabled

    @drivers         = Driver.for_provider current_provider_id
    @start_pickup_date = Time.zone.at(session[:trips_start].to_i).to_date
    @end_pickup_date = Time.zone.at(session[:trips_end].to_i).to_date
    @days_of_week = trip_sessions[:days_of_week].blank? ? [0,1,2,3,4,5,6] : trip_sessions[:days_of_week].split(',').map(&:to_i)
    if can? :edit, Trip
      @trip_results = TripResult.by_provider(current_provider).order(:name).pluck(:name, :id)
    end

    if @start_pickup_date > @end_pickup_date
      flash.now[:alert] = TranslationEngine.translate_text(:from_date_cannot_later_than_to_date)
    else
      flash.now[:alert] = nil
    end

    runs = get_eligible_runs(trip_sessions)
    @run_listings = runs.pluck(:name, :id) 
    @run_listings += [[TranslationEngine.translate_text(:cab), -1]] if cab_enabled
    @run_listings += [[TranslationEngine.translate_text(:unscheduled), -2]]

    @funding_sources = FundingSource.by_provider(current_provider).pluck(:name, :id) 

    respond_to do |format|
      format.html
      format.xml  { render :xml => @trips }
      format.json { render :json => @trips }
    end
  end

  def report
    @start_pickup_date = Time.zone.at(session[:trips_start].to_i).to_date
    @end_pickup_date = Time.zone.at(session[:trips_end].to_i).to_date
    filter_trips

    render layout: false
  end

  # list trips for a specific customer within given date range
  def customer_trip_summary
    @customer = Customer.find_by_id params[:customer_id]
    @trips = Trip.where(customer_id: params[:customer_id])

    if params[:past_trips].present?
      @trips = @trips.order(pickup_time: :desc).prior_to(DateTime.now).limit(params[:past_trips])
    elsif params[:future_trips].present?
      @trips = @trips.order(pickup_time: :asc).after(DateTime.now).limit(params[:future_trips])
    else
      unless params[:start_date].blank? && params[:end_date].blank?
        utility = Utility.new
        if !params[:start_date].blank?
          t_start = utility.parse_date params[:start_date]
          @trips = @trips.where("pickup_time >= '#{t_start.beginning_of_day.utc.strftime "%Y-%m-%d %H:%M:%S"}'")
        end

        if !params[:end_date].blank?
          t_end = utility.parse_date params[:end_date]
          @trips = @trips.where("pickup_time <= '#{t_end.end_of_day.utc.strftime "%Y-%m-%d %H:%M:%S"}'")
        end
        @trips = @trips.order(pickup_time: :asc)
      else
        # last 10 trips by default
        @trips = @trips.order(pickup_time: :desc).prior_to(DateTime.now).limit(10)
      end
    end

    respond_to do |format|
      format.js
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
      @trip.called_back_at = Time.current
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

  def callback
    @trip = Trip.find(params[:trip_id])
    @prev_customer_informed = @trip.customer_informed ? true: false

    if can? :edit, @trip
      @trip.customer_informed = params[:trip][:customer_informed]
      if !@trip.save(validate: false)
        @message = @trip.errors.full_messages.join(';')
      end
    else
      @message = TranslationEngine.translate_text(:operation_not_authorized)
    end

    respond_to do |format|
      format.js
    end
  end

  def notify_driver
    @trip = Trip.find(params[:trip_id])
    @prev_driver_notified = @trip.driver_notified ? true: false

    if can? :edit, @trip
      @trip.driver_notified = params[:trip][:driver_notified]
      if !@trip.save(validate: false)
        @message = @trip.errors.full_messages.join(';')
      end
    else
      @message = TranslationEngine.translate_text(:operation_not_authorized)
    end

    respond_to do |format|
      format.js
    end
  end

  def change_result
    @trip = Trip.find(params[:trip_id])
    @prev_trip_result_id = @trip.trip_result_id

    if can? :edit, @trip
      @trip.attributes = change_result_params
      @trip.save(validate: false)

      @trip_result_filters = trip_sessions[:trip_result_id]
      @clear_trip_status = true if @trip.scheduled? && @trip.is_cancelled_or_turned_down?

      @trip.post_process_trip_result_changed!(current_user)
    else
      @message = TranslationEngine.translate_text(:operation_not_authorized)
    end

    respond_to do |format|
      format.js
    end
  end

  def new
    @trip = Trip.new(:provider_id => current_provider_id)

    if params[:run_id]
      case params[:run_id].to_i 
      when Run::UNSCHEDULED_RUN_ID
      when Run::STANDBY_RUN_ID
        @trip.is_stand_by = true
      when Run::CAB_RUN_ID
        @trip.cab = true 
      else
        run = Run.find_by_id(params[:run_id])
        if run 
          @trip.run_id = run.id 
          @trip.date = run.date
        end
      end
    end

    if params[:customer_id] && customer = Customer.find_by_id(params[:customer_id])
      @trip.customer_id = customer.id
      @trip.pickup_address_id = customer.address_id if customer.address.try(:the_geom).present?
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

  def clone
    @trip = @trip.clone_for_future!
    @is_clone = true
    prep_view

    respond_to do |format|
      format.html { render action: :new }
      format.xml  { render :xml => @trip }
      format.js   { @remote = true; render :json => {:form => render_to_string(:partial => 'form') }, :content_type => "text/json" }
    end
  end

  def return
    @is_return = true
    if params[:trip].present?
      @trip = @trip.clone_for_return!(params[:trip][:pickup_time], params[:trip][:appointment_time])
    else
      @trip = @trip.clone_for_return!
    end

    prep_view

    respond_to do |format|
      format.html { render action: :new }
      format.xml  { render :xml => @trip }
      format.js   { @remote = true; render :json => {:form => render_to_string(:partial => 'form') }, :content_type => "text/json" }
    end
  end

  def show
    @trip = Trip.find(params[:id])
    prep_view

    authorize! :show, @trip unless @trip.customer && @trip.customer.authorized_for_provider(current_provider.id)

    respond_to do |format|
      format.html
      format.js  { @remote = true; render :json => {:form => render_to_string(:partial => 'form')}, :content_type => "text/json" }
    end
  end

  def create
    params[:trip][:provider_id] = current_provider_id
    handle_trip_params params[:trip]
    @trip = Trip.new(trip_params)
    process_address
    authorize! :manage, @trip

    if @trip.is_return? && @trip.outbound_trip.try(:is_stand_by)
      @trip.is_stand_by = true
    end

    if params[:run_id].present?
      status_id = params[:run_id].to_i
      case status_id
      when Run::STANDBY_RUN_ID
        @trip.is_stand_by = true
      when Run::CAB_RUN_ID
        @trip.cab = true
      else 
        if status_id != Run::UNSCHEDULED_RUN_ID
          run_id = status_id 
        end
      end
    end
    
    edit_mobilities

    from_dispatch = params[:from_dispatch] == 'true'

    respond_to do |format|
      if @trip.is_all_valid?(current_provider_id) && @trip.save
        if run_id
          scheduler = TripScheduler.new(@trip.id, run_id)
          scheduler.execute

          if scheduler && scheduler.errors.any?
            @trip_warning = "Trip was successfully created, but can not be assigned to run due to: #{scheduler.errors.join(',')}."
          end

          @trip.run.add_trip_manifest!(@trip.id) if @trip.run
        end

        @trip.post_process_trip_result_changed!(current_user)
        @trip.update_donation current_user, params[:customer_donation].to_f if params[:customer_donation].present?
        TripDistanceCalculationWorker.perform_async(@trip.id) #sidekiq needs to run
        @ask_for_return_trip = true if @trip.is_outbound?
        if @trip.is_return?
          TrackerActionLog.create_return_trip(@trip, current_user)
        else
          TrackerActionLog.create_trip(@trip, current_user)
        end
        format.html {
          if @ask_for_return_trip
            render action: :show
          else
            trip_notice = @trip_warning || 'Trip was successfully created.'

            if from_dispatch
              redirect_to dispatchers_path(run_id: params[:run_id]), :notice => trip_notice
            else
              redirect_to(@trip, :notice => trip_notice)
            end
          end
        }
      else
        prep_view
        format.html { render :action => "new" }
      end
    end

  end

  # Check if trip is potentially double booked. Returns an array of possible double booked trips
  def check_double_booked
    params = check_double_booked_params
    unless params[:customer_id].blank? || params[:date].blank?
      @customer = Customer.find_by_id(params[:customer_id])
      if @customer
        double_booked_trips = @customer.trips.for_date(Date.parse(params[:date]))
          .where.not(id: params[:id]).order(:pickup_time, :appointment_time)

        double_booked_trips_json = double_booked_trips.map do |trip|
          {
            id: trip.id,
            pickup_time: trip.pickup_time.try(:to_s, :time_only),
            pickup_address: trip.pickup_address.try(:address_text),
            appointment_time: trip.appointment_time.try(:to_s, :time_only),
            dropoff_address: trip.dropoff_address.try(:address_text)
          }
        end
      end
    end 
      
    respond_to do |format|
      format.js {
        render json: { trips: double_booked_trips_json || [] }
      }
    end
  end

  def update
    if params[:trip][:customer_id] && customer = Customer.find_by_id(params[:trip][:customer_id])
      authorize! :read, customer
    else
      params[:trip][:customer_id] = @trip.customer_id
    end
    handle_trip_params params[:trip]
    process_address
    authorize! :manage, @trip

    @trip.assign_attributes(trip_params)
    
    edit_mobilities

    is_address_changed = @trip.pickup_address_id_changed? || @trip.dropoff_address_id_changed?
    is_trip_result_changed = @trip.trip_result_id_changed?
    is_run_disrupted = @trip.run_disrupted_by_trip_changes?
    trip_result_changed = @trip.changes.include?(:trip_result_id)
    respond_to do |format|
      if @trip.is_all_valid?(current_provider_id) && @trip.save
        @trip.post_process_trip_result_changed!(current_user) if trip_result_changed
        @trip.unschedule_trip if is_run_disrupted
        @trip.update_donation current_user, params[:customer_donation].to_f if params[:customer_donation].present?
        TripDistanceCalculationWorker.perform_async(@trip.id) if is_address_changed
        TrackerActionLog.cancel_or_turn_down_trip(@trip, current_user) if is_trip_result_changed && @trip.is_cancelled_or_turned_down? 

        format.html {
          if params[:from_dispatch] == 'true'
            redirect_to dispatchers_path(run_id: @trip.run_id), :notice => 'Trip was successfully updated.'  
          else
            redirect_to @trip, :notice => 'Trip was successfully updated.'  
          end
        }
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
    run = @trip.run 
    run.delete_trip_manifest!(@trip.id) if run
    @trip.destroy
    #if run 
    #  TrackerActionLog.trips_removed_from_run(run, [@trip], current_user)
    #end

    respond_to do |format|
      format.html { redirect_to(trips_url) }
      format.xml  { head :ok }
      format.js   { render :json => {:status => "success"}, :content_type => "text/json" }
    end
  end

  def update_run_filters
    filters_hash = params[:trip_filters].try(:symbolize_keys) || {}
    runs = get_eligible_runs(filters_hash)
    @run_listings = runs.pluck(:name, :id) 
    @run_listings += [[TranslationEngine.translate_text(:cab), -1]] if current_provider.try(:cab_enabled?)
    @run_listings += [[TranslationEngine.translate_text(:unscheduled), -2]]

    @funding_sources = FundingSource.by_provider(current_provider).pluck(:name, :id) 
  end

  private

  def trip_params
    params.require(:trip).permit(
      :date, # virtual attribute used in setting pickup and appointment times
      :direction,
      :linking_trip_id,
      :appointment_time,
      :customer_id,
      :customer_informed,
      :driver_id,
      :dropoff_address_id,
      :dropoff_address_notes,
      :funding_source_id,
      :medicaid_eligible,
      :mileage,
      :mobility_id,
      :notes,
      :pickup_address_id,
      :pickup_address_notes,
      :pickup_time,
      :provider_id, # We normally wouldn't accept this and would set it manually on the instance, but in this controller we're setting it in the params dynamically
      :cab,
      :is_stand_by,
      :service_level_id,
      :trip_purpose_id,
      :trip_result_id,
      :result_reason,
      :vehicle_id,
      :number_of_senior_passengers_served,
      :number_of_disabled_passengers_served,
      :number_of_low_income_passengers_served,
      :passenger_load_min,
      :passenger_unload_min,
      :early_pickup_allowed,
      :fare_amount,
      customer_attributes: [:id],
      fare_attributes: [
        :id,
        :fare_type,
        :pre_trip
      ]
    )
  end

  def prep_view
    @customer           = @trip.customer
    @mobilities         = Mobility.by_provider(current_provider).order(:name)
    @funding_sources    = FundingSource.by_provider(current_provider)
    @trip_results       = TripResult.by_provider(current_provider).order(:name).pluck(:name, :id)
    @trip_purposes      = TripPurpose.by_provider(current_provider).order(:name)
    @drivers            = Driver.active.for_provider @trip.provider_id
    @trips              = [] if @trips.nil?
    @vehicles           = Vehicle.active.for_provider(@trip.provider_id)
    @vehicles           = add_cab(@vehicles) if current_provider.try(:cab_enabled?)
    @repeating_vehicles = @vehicles
    @service_levels     = ServiceLevel.by_provider(current_provider).order(:name).pluck(:name, :id)
  end

  # Strong params for changing trip result and result_reason
  def change_result_params
    params.require(:trip).permit(:trip_result_id, :result_reason)
  end

  def handle_trip_params(trip_params)
    if trip_params[:customer_informed] and not @trip.customer_informed
      trip_params[:called_back_by] = current_user
      trip_params[:called_back_at] = DateTime.current.to_s
    end
  end

  def filter_trips
    @trips = Trip.for_provider(current_provider_id).includes(:customer, :pickup_address, {:run => [:driver, :vehicle]}).distinct
    .references(:customer, :pickup_address, {:run => [:driver, :vehicle]}).order(:pickup_time)

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
      session["trips_#{key}"] = val if !val.nil?
    end
  end

  def trip_sessions
    {
      start: session[:trips_start],
      end: session[:trips_end],
      customer_id: session[:trips_customer_id],
      trip_result_id: session[:trips_trip_result_id],
      status_id: session[:trips_status_id],
      funding_source_id: session[:trips_funding_source_id],
      days_of_week: session[:trips_days_of_week]
    }
  end

  def get_eligible_runs(filter_params)
    runs = Run.for_provider(current_provider_id).reorder(nil).default_order
    runs = RunFilter.new(runs,filter_params).filter!
  end
  
  def check_double_booked_params
    params.require(:trip).permit(:id, :customer_id, :date)
  end

  def add_cab(vehicles)
    cab_vehicle = Vehicle.new :name => "Cab"
    cab_vehicle.id = -1
    [cab_vehicle] + vehicles
  end

  def process_address
    if params[:trip][:pickup_address_id].blank? 
      if !params[:trip_pickup_google_address].blank?
        addr_params = JSON(params[:trip_pickup_google_address])
        new_temp_addr = TempAddress.new(addr_params.select{|x| TempAddress.allowable_params.include?(x)})
        new_temp_addr.the_geom = Address.compute_geom(addr_params['lat'], addr_params['lon'])
        @trip.pickup_address = new_temp_addr
      elsif !params[:trip_pickup_lat].blank? && !params[:trip_pickup_lon].blank?
        new_temp_addr = GeocodedAddress.new
        new_temp_addr.the_geom = Address.compute_geom(params['trip_pickup_lat'], params['trip_pickup_lon'])
        @trip.pickup_address = new_temp_addr
      end
    end

    if params[:trip][:dropoff_address_id].blank? 
      if !params[:trip_dropoff_google_address].blank?
        addr_params = JSON(params[:trip_dropoff_google_address])
        new_temp_addr = TempAddress.new(addr_params.select{|x| TempAddress.allowable_params.include?(x)})
        new_temp_addr.the_geom = Address.compute_geom(addr_params['lat'], addr_params['lon'])
        @trip.dropoff_address = new_temp_addr
      elsif !params[:trip_dropoff_lat].blank? && !params[:trip_dropoff_lon].blank?
        new_temp_addr = GeocodedAddress.new
        new_temp_addr.the_geom = Address.compute_geom(params['trip_dropoff_lat'], params['trip_dropoff_lon'])
        @trip.dropoff_address = new_temp_addr
      end
    end
  end

  def edit_mobilities
    unless params[:mobilities].blank?
      mobilities = JSON.parse(params[:mobilities], symbolize_names: true)
      @trip.ridership_mobilities.delete_all

      sum_by_ridership = {}
      mobilities.each do |config|
        ridership_id = config[:ridership_id].to_i
        capacity = config[:capacity].to_i
        sum_by_ridership[ridership_id] = 0 if !sum_by_ridership.has_key?(ridership_id)
        sum_by_ridership[ridership_id] += capacity
        @trip.ridership_mobilities.build(mobility_id: config[:mobility_id], ridership_id: ridership_id, capacity: capacity)
      end

      # update space totals
      @trip.customer_space_count = sum_by_ridership[1].to_i
      @trip.guest_count = sum_by_ridership[2].to_i
      @trip.attendant_count = sum_by_ridership[3].to_i
      @trip.service_animal_space_count = sum_by_ridership[4].to_i
    end
  end
end
