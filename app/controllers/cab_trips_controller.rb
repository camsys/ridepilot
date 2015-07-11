class CabTripsController < ApplicationController
  before_filter :set_date_params

  def index
    authorize! :manage, current_provider
    @dates_in_range = (@week_start.to_date..@week_end.to_date).to_a
    @cab_trips = Trip.for_provider(current_provider_id).for_cab.for_date_range(@week_start, @week_end)
    @grouped_cab_trips = @cab_trips.group_by{|t| t.date.to_s}
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cab_trips }
      format.js {
        render :json => { :rows => [render_to_string(:partial => "grouped_cab_trips.html")] }
      }
    end
  end
  
  def edit_multiple
    authorize! :manage, current_provider
    @drivers = Driver.where(:provider_id => current_provider_id)
    @vehicles = Vehicle.active.where(:provider_id => current_provider_id)
    @trip_results = TripResult.pluck(:name, :code)
    @cab_trips = Trip.for_provider(current_provider_id).for_cab.for_date(Time.at params[:start].to_i)
    respond_to do |format|
      format.html
      format.xml  { render :xml => @cab_trips }
    end
  end

  def update_multiple
    authorize! :manage, current_provider
    @trips = Trip.update(params[:cab_trips].keys, params[:cab_trips].values)
    @errors = @trips.delete_if { |t| t.errors.any? }
    respond_to do |format|
      if @trips.any?      
        format.html { redirect_to(cab_trips_path(date_range(@trips.first)), :notice => ActionController::Base.helpers.pluralize(@trips.size, 'cab trip') + ' updated successfully') }
        format.xml  { head :ok }
      else
        format.html { redirect_to(cab_trips_path(date_range(@trips.first)), :alert => ActionController::Base.helpers.pluralize(@errors.size, 'cab trip') + ' could not be updated') }
        format.xml  { render :xml => @errors, :status => :unprocessable_entity }
      end
    end
  end
  
  private
  
  def set_date_params
    if params[:end].present? && params[:start].present?
      @week_start = Time.at params[:start].to_i
      @week_end   = Time.at params[:end].to_i
    else
      time     = Time.now
      @week_start = time.beginning_of_week
      @week_end   = @week_start + 6.days
    end
  end

  def date_range(cab_trip)
    if cab_trip.try(:pickup_time)
      week_start = cab_trip.pickup_time.beginning_of_week
      {:start => week_start.to_time.to_i, :end => (week_start + 6.days).to_time.to_i } 
    end
  end
end
