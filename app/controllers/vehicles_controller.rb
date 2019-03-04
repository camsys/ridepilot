class VehiclesController < ApplicationController
  load_and_authorize_resource except: [:change_initial_mileage, :inactivate, :reactivate]

  def index
    @vehicles = @vehicles.default_order.for_provider(current_provider.id)
    @vehicles = @vehicles.active if params[:show_inactive] != 'true'
  end

  def show
    @readonly = true
  end

  def new
    @vehicle.provider = current_provider
  end

  def edit; end

  def update
    new_attrs = vehicle_params
    is_garage_address_blank = check_blank_garage_address

    if is_garage_address_blank
      prev_garage_address = @vehicle.garage_address
      @vehicle.garage_address_id = nil
      new_attrs = new_attrs.except(:garage_address_attributes)
    end

    @vehicle.assign_attributes new_attrs

    if !params[:address_lat].blank? && !params[:address_lon].blank?
      @vehicle.build_garage_address.the_geom = Address.compute_geom(params[:address_lat], params[:address_lon])
    elsif @vehicle.garage_address.present?
      @vehicle.garage_address.the_geom = Address.compute_geom(params[:lat], params[:lon])
    end

    if !@vehicle.is_all_valid?(current_provider_id)
      render action: :edit
    else
      begin      
        Vehicle.transaction do
          @vehicle.save!
          prev_garage_address.destroy if is_garage_address_blank && prev_garage_address.present?
        end
        redirect_to @vehicle, notice: 'Vehicle was successfully updated.'
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug e.message
        render action: :edit
      end
    end
  end

  def create
    new_attrs = vehicle_params
    is_garage_address_blank = check_blank_garage_address
    if is_garage_address_blank
      new_attrs = new_attrs.except(:garage_address_attributes)
    end

    @vehicle.attributes = new_attrs

    if is_garage_address_blank
      @vehicle.garage_address = nil
    elsif !params[:address_lat].blank? && !params[:address_lon].blank?
      @vehicle.build_garage_address.the_geom = Address.compute_geom(params[:address_lat], params[:address_lon])
    elsif @vehicle.garage_address.present?
      @vehicle.garage_address.the_geom = Address.compute_geom(params[:lat], params[:lon])
    end

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

  def edit_initial_mileage
    @vehicle = Vehicle.find_by_id(params[:id])
    authorize! :edit, @vehicle
  end

  def update_initial_mileage
    @vehicle = Vehicle.find_by_id(params[:id])
    authorize! :edit, @vehicle

    prev_mileage = @vehicle.initial_mileage
    @vehicle.assign_attributes change_initial_mileage_params

    respond_to do |format|
      format.html {
        if @vehicle.initial_mileage_change_reason.blank?
          flash.now[:error] = "Please provide a reason."
          render action: :edit_initial_mileage
        else
          @vehicle.save(validate: false)
          TrackerActionLog.change_vehicle_initial_mileage @vehicle, current_user, prev_mileage
          redirect_to @vehicle, notice: "Initial mileage has been updated."
        end
      }
    end
  end

  def inactivate
    @vehicle = Vehicle.find_by_id(params[:id])

    authorize! :update, @vehicle
    
    prev_active_text = @vehicle.active_status_text
    prev_reason = @vehicle.active_status_changed_reason

    @vehicle.assign_attributes vehicle_inactivate_params

    if @vehicle.inactivated?
      if @vehicle.permanent_inactivated?
        @vehicle.inactivated_start_date = nil
        @vehicle.inactivated_end_date = nil
      else
        if @vehicle.inactivated_end_date.present? && !@vehicle.inactivated_start_date.present?
          @vehicle.inactivated_start_date = Date.today.in_time_zone
        end
      end
    else
      @vehicle.active_status_changed_reason = nil  
    end

    if @vehicle.changed?
      TrackerActionLog.vehicle_active_status_changed(@vehicle, current_user, prev_active_text, prev_reason)
    end

    @vehicle.save(validate: false)

    redirect_to @vehicle
  end

  def reactivate
    @vehicle = Vehicle.find(params[:id])
    authorize! :edit, @vehicle

    prev_active_text = @vehicle.active_status_text
    prev_reason = @vehicle.active_status_changed_reason

    @vehicle.reactivate!
    TrackerActionLog.vehicle_active_status_changed(@vehicle, current_user, prev_active_text, prev_reason)

    redirect_to @vehicle
  end

  private

  def vehicle_params
    params.require(:vehicle).permit(
      :name, 
      :year, 
      :make, 
      :model, 
      :license_plate, 
      :vin, 
      :reportable, 
      :is_5310_reportable, 
      :insurance_coverage_details, 
      :ownership, 
      :responsible_party, 
      :registration_expiration_date, 
      :accessibility_equipment, 
      :initial_mileage,
      :garage_phone_number,
      :vehicle_maintenance_schedule_type_id,
      :vehicle_type_id,
      :garage_address_attributes => [
        :provider_id,
        :address,
        :city,
        :state,
        :zip
      ])
  end

  def vehicle_inactivate_params
    params.require(:vehicle).permit(
      :active,
      :inactivated_start_date,
      :inactivated_end_date,
      :active_status_changed_reason
    )
  end

  def change_initial_mileage_params
    params.require(:vehicle).permit(:initial_mileage, :initial_mileage_change_reason)
  end

  def check_blank_garage_address
    address_params = vehicle_params[:garage_address_attributes]
    is_blank = true
    address_params.keys.each do |key|
      next if key.to_s == 'provider_id'
      unless address_params[key].blank?
        is_blank = false
        break
      end
    end if address_params

    is_blank && params[:address_lat].blank? && params[:address_lon].blank?
  end
  
end
