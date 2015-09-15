class RecurringVehicleMaintenanceCompliancesController < ApplicationController
  load_and_authorize_resource skip: [:schedule_preview, :future_schedule_preview, :compliance_based_schedule_preview]
  
  before_filter :prep_form, only: [:new, :edit, :create, :update]  
  before_filter :prep_preview, only: [:schedule_preview, :future_schedule_preview, :compliance_based_schedule_preview]
  before_filter :generate_schedule_previews, only: [:show, :edit, :create, :update]
  
  # GET /recurring_vehicle_maintenance_compliances
  def index
    # Limit what super admins see on the index
    @recurring_vehicle_maintenance_compliances = @recurring_vehicle_maintenance_compliances.where(provider: current_provider)
  end

  # GET /recurring_vehicle_maintenance_compliances/1
  def show
    @all_readonly = @readonly = true
  end

  # GET /recurring_vehicle_maintenance_compliances/new
  def new
  end

  # GET /recurring_vehicle_maintenance_compliances/1/edit
  def edit
  end

  # POST /recurring_vehicle_maintenance_compliances
  def create
    @recurring_vehicle_maintenance_compliance.provider = current_provider
    if @recurring_vehicle_maintenance_compliance.save
      redirect_to @recurring_vehicle_maintenance_compliance, notice: 'Recurring vehicle maintenance compliance was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /recurring_vehicle_maintenance_compliances/1
  def update
    if @recurring_vehicle_maintenance_compliance.update(recurring_vehicle_maintenance_compliance_params)
      redirect_to @recurring_vehicle_maintenance_compliance, notice: 'Recurring vehicle maintenance compliance was successfully updated.'
    else
      render :edit
    end
  end

  # GET /recurring_vehicle_maintenance_compliances/1/delete
  def delete
  end
  
  # DELETE /recurring_vehicle_maintenance_compliances/1
  def destroy
    if params[:destroy_with_incomplete_children] == "1"
      @recurring_vehicle_maintenance_compliance.destroy_with_incomplete_children!
    else
      @recurring_vehicle_maintenance_compliance.destroy
    end
    redirect_to recurring_vehicle_maintenance_compliances_url, notice: 'Recurring vehicle maintenance compliance was successfully destroyed.'
  end
  
  # GET /recurring_vehicle_maintenance_compliances/schedule_preview
  def schedule_preview
    generate_schedule_preview
    render partial: "schedule_preview"
  end

  # GET /recurring_vehicle_maintenance_compliances/future_schedule_preview
  def future_schedule_preview
    generate_future_schedule_preview
    render partial: "future_schedule_preview"
  end

  # GET /recurring_vehicle_maintenance_compliances/compliance_based_schedule_preview
  def compliance_based_schedule_preview
    generate_compliance_based_schedule_preview
    render partial: "compliance_based_schedule_preview"
  end
  
  # PUT /recurring_vehicle_maintenance_compliances/generate
  def generate!
    # This is in place only for testing. In production we would rely on a cron 
    # task to generate these regularly
    raise ActionController::RoutingError if Rails.env.production? or Rails.env.staging?
    RecurringVehicleMaintenanceCompliance.generate! date_range_length: 5.years, mileage_range_length: 30_000
    redirect_to recurring_vehicle_maintenance_compliances_url, notice: 'All recurring vehicle maintenance compliance events have been generated.'
  end  

  private

  # Only allow a trusted parameter "white list" through.
  def recurring_vehicle_maintenance_compliance_params
    params.require(:recurring_vehicle_maintenance_compliance).permit(
      :event_name,
      :event_notes,
      :recurrence_type,
      :recurrence_schedule,
      :recurrence_frequency,
      :recurrence_mileage,
      :recurrence_notes,
      :start_date,
      :future_start_rule,
      :future_start_schedule,
      :future_start_frequency,
      :compliance_based_scheduling,
    )
  end
  
  def generate_schedule_preview
    @schedule_preview = if @recurring_vehicle_maintenance_compliance.compliance_based_scheduling?
      case @recurring_vehicle_maintenance_compliance.recurrence_type.try(:to_sym)
      when :date
        # Return the first start date
        [{due_date: @recurring_vehicle_maintenance_compliance.start_date}]
      when :mileage
        # Assumes a vehicle with a last_odometer_reading of 0
        [{due_mileage: @recurring_vehicle_maintenance_compliance.recurrence_mileage}]
      when :both
        [{due_date: @recurring_vehicle_maintenance_compliance.start_date, due_mileage: @recurring_vehicle_maintenance_compliance.recurrence_mileage}]
      end
    else
      case @recurring_vehicle_maintenance_compliance.recurrence_type.try(:to_sym)
      when :date
        # Return the first 6 occurrences, beginning with the start date
        RecurringVehicleMaintenanceCompliance.occurrence_dates_on_schedule_in_range(@recurring_vehicle_maintenance_compliance, range_start_date: Date.current, range_end_date: (@recurring_vehicle_maintenance_compliance.start_date + (@recurring_vehicle_maintenance_compliance.recurrence_frequency * 5).send(@recurring_vehicle_maintenance_compliance.recurrence_schedule))).map{ |occurrence| {due_date: occurrence} }
      when :mileage
        # Assumes a vehicle with a last_odometer_reading of 0
        RecurringVehicleMaintenanceCompliance.occurrence_mileages_on_schedule_in_range(@recurring_vehicle_maintenance_compliance, range_start_mileage: @recurring_vehicle_maintenance_compliance.recurrence_mileage, range_end_mileage: (@recurring_vehicle_maintenance_compliance.recurrence_mileage * 6)).map{ |occurrence| {due_mileage: occurrence} }
      when :both
        dates = RecurringVehicleMaintenanceCompliance.occurrence_dates_on_schedule_in_range @recurring_vehicle_maintenance_compliance, range_start_date: Date.current, range_end_date: (@recurring_vehicle_maintenance_compliance.start_date + (@recurring_vehicle_maintenance_compliance.recurrence_frequency * 5).send(@recurring_vehicle_maintenance_compliance.recurrence_schedule))
        mileages = RecurringVehicleMaintenanceCompliance.occurrence_mileages_on_schedule_in_range @recurring_vehicle_maintenance_compliance, range_start_mileage: @recurring_vehicle_maintenance_compliance.recurrence_mileage, range_end_mileage: (@recurring_vehicle_maintenance_compliance.recurrence_mileage * 6)
        dates.zip(mileages).map{ |date, mileage| {due_date: date, due_mileage: mileage} }
      end
    end.collect{ |occurrences| due_string occurrences }
  end
  
  def generate_future_schedule_preview
    @future_schedule_preview = if @recurring_vehicle_maintenance_compliance.compliance_based_scheduling?
      case @recurring_vehicle_maintenance_compliance.recurrence_type.try(:to_sym)
      when :date
        # Return the adjusted_start_date, as of the day after the start date
        [{due_date: RecurringVehicleMaintenanceCompliance.adjusted_start_date(@recurring_vehicle_maintenance_compliance, as_of: @recurring_vehicle_maintenance_compliance.start_date.tomorrow)}]
      when :mileage
        # Assumes a vehicle with a last_odometer_reading of 0
        [{due_mileage: @recurring_vehicle_maintenance_compliance.recurrence_mileage}]
      when :both
        [{due_date: RecurringVehicleMaintenanceCompliance.adjusted_start_date(@recurring_vehicle_maintenance_compliance, as_of: @recurring_vehicle_maintenance_compliance.start_date.tomorrow), due_mileage: @recurring_vehicle_maintenance_compliance.recurrence_mileage}]
      end
    else
      case @recurring_vehicle_maintenance_compliance.recurrence_type.try(:to_sym)
      when :date
        # Return the first 6 occurrences, as of the day after the start date
        adjusted_start_date = RecurringVehicleMaintenanceCompliance.adjusted_start_date(@recurring_vehicle_maintenance_compliance, as_of: @recurring_vehicle_maintenance_compliance.start_date.tomorrow)
        RecurringVehicleMaintenanceCompliance.occurrence_dates_on_schedule_in_range(@recurring_vehicle_maintenance_compliance, first_date: adjusted_start_date, range_end_date: (adjusted_start_date + (@recurring_vehicle_maintenance_compliance.recurrence_frequency * 5).send(@recurring_vehicle_maintenance_compliance.recurrence_schedule))).map{ |occurrence| {due_date: occurrence} }
      when :mileage
        # Assumes a vehicle with a last_odometer_reading of 0
        RecurringVehicleMaintenanceCompliance.occurrence_mileages_on_schedule_in_range(@recurring_vehicle_maintenance_compliance, range_start_mileage: @recurring_vehicle_maintenance_compliance.recurrence_mileage, range_end_mileage: (@recurring_vehicle_maintenance_compliance.recurrence_mileage * 6)).map{ |occurrence| {due_mileage: occurrence} }
      when :both
        adjusted_start_date = RecurringVehicleMaintenanceCompliance.adjusted_start_date(@recurring_vehicle_maintenance_compliance, as_of: @recurring_vehicle_maintenance_compliance.start_date.tomorrow)
        dates = RecurringVehicleMaintenanceCompliance.occurrence_dates_on_schedule_in_range @recurring_vehicle_maintenance_compliance, first_date: adjusted_start_date, range_end_date: (adjusted_start_date + (@recurring_vehicle_maintenance_compliance.recurrence_frequency * 5).send(@recurring_vehicle_maintenance_compliance.recurrence_schedule))
        mileages = RecurringVehicleMaintenanceCompliance.occurrence_mileages_on_schedule_in_range @recurring_vehicle_maintenance_compliance, range_start_mileage: @recurring_vehicle_maintenance_compliance.recurrence_mileage, range_end_mileage: (@recurring_vehicle_maintenance_compliance.recurrence_mileage * 6)
        dates.zip(mileages).map{ |date, mileage| {due_date: date, due_mileage: mileage} }
      end
    end.collect{ |occurrences| due_string occurrences }
  end
  
  def generate_compliance_based_schedule_preview
    @compliance_based_schedule_preview = case @recurring_vehicle_maintenance_compliance.recurrence_type.try(:to_sym)
    when :date
      # Return the next occurance date, as of the day after the start date
      assumed_completion_date = @recurring_vehicle_maintenance_compliance.start_date + 1.day
      [{due_date: RecurringVehicleMaintenanceCompliance.next_occurrence_date_from_previous_date_in_range(@recurring_vehicle_maintenance_compliance, assumed_completion_date, range_end_date: (assumed_completion_date + @recurring_vehicle_maintenance_compliance.recurrence_frequency.send(@recurring_vehicle_maintenance_compliance.recurrence_schedule)))}]
    when :mileage
      assumed_completion_mileage = 100 # miles
      [{due_mileage: RecurringVehicleMaintenanceCompliance.next_occurrence_mileage_from_previous_mileage_in_range(@recurring_vehicle_maintenance_compliance, assumed_completion_mileage, range_end_mileage: assumed_completion_mileage + (@recurring_vehicle_maintenance_compliance.recurrence_mileage * 6))}]
    when :both
      assumed_completion_date = @recurring_vehicle_maintenance_compliance.start_date + 1.day
      assumed_completion_mileage = 100 # miles
      [{due_date: RecurringVehicleMaintenanceCompliance.next_occurrence_date_from_previous_date_in_range(@recurring_vehicle_maintenance_compliance, assumed_completion_date, range_end_date: (assumed_completion_date + @recurring_vehicle_maintenance_compliance.recurrence_frequency.send(@recurring_vehicle_maintenance_compliance.recurrence_schedule))), due_mileage: RecurringVehicleMaintenanceCompliance.next_occurrence_mileage_from_previous_mileage_in_range(@recurring_vehicle_maintenance_compliance, assumed_completion_mileage, range_end_mileage: assumed_completion_mileage + (@recurring_vehicle_maintenance_compliance.recurrence_mileage * 6))}]
    end.collect{ |occurrences| due_string occurrences }
  end
  
  def prep_form
    @readonly = @recurring_vehicle_maintenance_compliance.vehicle_maintenance_compliances.any?
  end
  
  def prep_preview
    @recurring_vehicle_maintenance_compliance = RecurringVehicleMaintenanceCompliance.new recurring_vehicle_maintenance_compliance_params
  end
  
  def generate_schedule_previews
    if @recurring_vehicle_maintenance_compliance.persisted? or @recurring_vehicle_maintenance_compliance.valid?
      generate_schedule_preview
      generate_future_schedule_preview
      generate_compliance_based_schedule_preview if @recurring_vehicle_maintenance_compliance.compliance_based_scheduling?
    end
  end
  
  def due_string(due_date: nil, due_mileage: nil)
    date = due_date.try(:to_s, :long)
    mileage = "#{ActionController::Base.helpers.number_with_delimiter due_mileage} mi" unless due_mileage.blank?
    if date.present? and mileage.present?
      "#{date} and #{mileage}"
    elsif date.present?
      date
    elsif mileage.present?
      mileage
    end
  end
end
