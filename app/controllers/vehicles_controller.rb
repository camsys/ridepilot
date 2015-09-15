class VehiclesController < ApplicationController
  load_and_authorize_resource

  def index
    @vehicles = @vehicles.default_order.for_provider(current_provider.id)
  end

  def show
    @readonly = true
  end

  def new
    @vehicle.provider = current_provider
  end

  def edit; end

  def update
    @vehicle.assign_attributes vehicle_params
    if @vehicle.is_all_valid?(current_provider_id) && @vehicle.save
      redirect_to @vehicle, notice: 'Vehicle was successfully updated.'
    else
      render action: :edit
    end 
  end

  def create
    @vehicle.provider = current_provider
    if @vehicle.is_all_valid?(current_provider_id) && @vehicle.save
      redirect_to @vehicle, notice: 'Vehicle was successfully created.'
    else
      render action: :new
    end
  end

  def destroy
    @vehicle.destroy
    redirect_to vehicles_path, notice: 'Vehicle was successfully deleted.'
  end

  private
  
  def vehicle_params
    params.require(:vehicle).permit(:name, :year, :make, :model, :license_plate, :vin, :garaged_location, :active, :default_driver_id, :reportable, :insurance_coverage_details, :ownership, :responsible_party, :registration_expiration_date, :seating_capacity, :accessibility_equipment)
  end
  
end
