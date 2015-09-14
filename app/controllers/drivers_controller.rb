class DriversController < ApplicationController
  load_and_authorize_resource

  def index
    @drivers = @drivers.for_provider(current_provider.id)
  end

  def show
    prep_edit(readonly: true)
  end

  def new
    @driver.provider = current_provider
    prep_edit
  end

  def edit
    prep_edit
  end

  def update
    if !@driver.is_all_valid?(current_provider_id)
      prep_edit
      render action: :edit
    else
      begin      
        Driver.transaction do
          @driver.update_attributes!(driver_params)
          create_or_update_hours!
        end
        redirect_to @driver, notice: 'Driver was successfully updated.'
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug e.message
        prep_edit
        render action: :edit
      end
    end
  end

  def create
    @driver.provider = current_provider
    if !@driver.is_all_valid?(current_provider_id)
      prep_edit
      render action: :new
    else
      begin
        Driver.transaction do
          @driver.save!
          create_or_update_hours!
        end
        redirect_to @driver, notice: 'Driver was successfully created.'
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug e.message
        prep_edit
        render action: :new
      end
    end
  end

  def destroy
    @driver.destroy
    redirect_to drivers_path, notice: 'Driver was successfully deleted.'
  end

  private
  
  def prep_edit(readonly: false)
    @readonly = readonly
    
    @available_users = @driver.provider.users - User.drivers(@driver.provider)
    @available_users << @driver.user if @driver.user
    
    @hours = @driver.hours_hash

    @start_hours = OperatingHours.available_start_times
    @end_hours = OperatingHours.available_end_times
    
    @driver.address ||= @driver.build_address provider: @driver.provider
  end
  
  def driver_params
    params.require(:driver).permit(
      :active, 
      :paid, 
      :name, 
      :email, 
      :user_id,
      :address_attributes => [
        :address,
        :building_name,
        :city,
        :name,
        :provider_id,
        :state,
        :zip,
        :notes,
        :phone_number
      ],
    )
  end
  
  def create_or_update_hours!
    params[:hours] ||= {}
    hours = @driver.hours_hash
    if !hours.empty? and hours.length < 7
      hours.each_pair { |day, h| h.destroy }
      hours = {}
    end
    if hours.empty?
      (0..6).each do |d|
        hours[d] = OperatingHours.new day_of_week: d, driver: @driver
      end
    end
    errors = false
    params[:hours].each_pair do |day, value|
      begin
        day = day.to_i
        day_hours = hours[day]
        if day_hours.nil?
          day_hours = OperatingHours.new day_of_week: day, driver: @driver
        end
        case value
        when 'unavailable'
          day_hours.make_unavailable
        when 'open24'
          day_hours.make_24_hours
        when 'open'
          day_hours.start_time = params[:start_hour][day.to_s]
          day_hours.end_time = params[:end_hour][day.to_s]
        else
          @driver.errors.add :operating_hours, 'must be "unavailable", "open24", or "open".'
          raise ActiveRecord::RecordInvalid.new(@driver)
        end
        day_hours.save!
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug e.message
        errors = true
      end
    end
    if errors
      raise ActiveRecord::RecordInvalid.new(@driver)
    end
  end
end
