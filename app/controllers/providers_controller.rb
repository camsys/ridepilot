class ProvidersController < ApplicationController
  load_and_authorize_resource

  def new
  end

  def create
    @provider.save!
    redirect_to provider_path(@provider)
  end

  def index
  end
  
  def show
    @unassigned_drivers = Driver.unassigned(@provider)
    @unassigned_vehicles = Vehicle.unassigned(@provider)
    array = (0..19).zip(0..19).map()
    @zoom_choices = array.inject({}) do |memo, values|
      memo[values.first.to_s] = values.last.to_s
      memo
    end
  end

  # POST /providers/:id/save_region
  def save_region
    north = params[:region_north].to_f
    west = params[:region_west].to_f
    south = params[:region_south].to_f
    east = params[:region_east].to_f
    if north == 0.0 and west == 0.0
      @provider.region_nw_corner = nil
    else
      @provider.region_nw_corner = RGeo::Geographic.spherical_factory(srid: 4326).point(west, north)
    end
    if south == 0.0 and east == 0.0
      @provider.region_se_corner = nil
    else
      @provider.region_se_corner = RGeo::Geographic.spherical_factory(srid: 4326).point(east, south)
    end
    @provider.save!
    redirect_to provider_path(@provider, anchor: "region")
  end

  # POST /providers/:id/save_viewport
  def save_viewport
    lat = params[:viewport_lat].to_f
    lng = params[:viewport_lng].to_f
    zoom = params[:viewport_zoom].to_i
    if zoom < 0 or zoom >= 20
      flash.now[:alert] = 'Zoom must be between 0 and 19.'
      redirect_to provider_path(@provider)
    end
    @provider.viewport_zoom = zoom
    if lat == 0.0 and lng == 0.0
      @provider.viewport_center = nil
      @provider.viewport_zoom = nil
    else
      @provider.viewport_center = RGeo::Geographic.spherical_factory(srid: 4326).point(lng, lat)
    end
    @provider.save!
    redirect_to provider_path(@provider, anchor: "viewport")
  end

  def delete_role
    role = Role.find(params[:role_id])
    user = role.user
    authorize! :edit, role
    role.destroy
    if user.roles.size == 0
      user.destroy
    end
    redirect_to provider_path(params[:provider_id])
  end

  def change_role
    role = Role.find(params[:role][:id])
    authorize! :edit, role
    role.level = params[:role][:level]
    role.save!
    redirect_to provider_path(params[:provider_id])
  end
  
  def change_dispatch
    @provider.update_attribute :dispatch, params[:dispatch]
    
    redirect_to provider_path(@provider)
  end
  
  def change_scheduling
    @provider.update_attribute :scheduling, params[:scheduling]
    redirect_to provider_path(@provider)
  end

  def change_allow_trip_entry_from_runs_page
    @provider.update_attribute :allow_trip_entry_from_runs_page, params[:allow_trip_entry_from_runs_page]
    redirect_to provider_path(@provider)
  end

  def change_reimbursement_rates
    @provider.update_attributes reimbursement_params
    redirect_to provider_path(@provider)
  end
  
  def change_fields_required_for_run_completion
    @provider.update_attribute :fields_required_for_run_completion, params[:fields_required_for_run_completion]
    redirect_to provider_path(@provider)
  end
  
  private
  
  def provider_params
    params.require(:provider).permit(:name, :logo, :dispatch, :scheduling, :region_nw_corner, :region_se_corner, :viewport_center, :viewport_zoom, :allow_trip_entry_from_runs_page, :oaa3b_per_ride_reimbursement_rate, :ride_connection_per_ride_reimbursement_rate, :trimet_per_ride_reimbursement_rate, :stf_van_per_ride_reimbursement_rate, :stf_taxi_per_ride_administrative_fee, :stf_taxi_per_ride_ambulatory_load_fee, :stf_taxi_per_ride_wheelchair_load_fee, :stf_taxi_per_mile_ambulatory_reimbursement_rate, :stf_taxi_per_mile_wheelchair_reimbursement_rate)
  end

  def reimbursement_params
    params.permit(*Provider::REIMBURSEMENT_ATTRIBUTES)
  end
end