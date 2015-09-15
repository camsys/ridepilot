class RecurringDriverCompliancesController < ApplicationController
  load_and_authorize_resource skip: [:schedule_preview, :future_schedule_preview, :compliance_based_schedule_preview]
  
  before_filter :prep_form, only: [:new, :edit, :create, :update]  
  before_filter :prep_preview, only: [:schedule_preview, :future_schedule_preview, :compliance_based_schedule_preview]
  before_filter :generate_schedule_previews, only: [:show, :edit, :create, :update]
  
  # GET /recurring_driver_compliances
  def index
    # Limit what super admins see on the index
    @recurring_driver_compliances = @recurring_driver_compliances.where(provider: current_provider)
  end

  # GET /recurring_driver_compliances/1
  def show
    @all_readonly = @readonly = true
  end

  # GET /recurring_driver_compliances/new
  def new
  end

  # GET /recurring_driver_compliances/1/edit
  def edit
  end

  # POST /recurring_driver_compliances
  def create
    @recurring_driver_compliance.provider = current_provider
    if @recurring_driver_compliance.save
      redirect_to @recurring_driver_compliance, notice: 'Recurring driver compliance was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /recurring_driver_compliances/1
  def update
    if @recurring_driver_compliance.update(recurring_driver_compliance_params)
      redirect_to @recurring_driver_compliance, notice: 'Recurring driver compliance was successfully updated.'
    else
      render :edit
    end
  end

  # GET /recurring_driver_compliances/1/delete
  def delete
  end
  
  # DELETE /recurring_driver_compliances/1
  def destroy
    if params[:destroy_with_incomplete_children] == "1"
      @recurring_driver_compliance.destroy_with_incomplete_children!
    else
      @recurring_driver_compliance.destroy
    end
    redirect_to recurring_driver_compliances_url, notice: 'Recurring driver compliance was successfully destroyed.'
  end
  
  # GET /recurring_driver_compliances/schedule_preview
  def schedule_preview
    generate_schedule_preview
    render partial: "schedule_preview"
  end

  # GET /recurring_driver_compliances/future_schedule_preview
  def future_schedule_preview
    generate_future_schedule_preview
    render partial: "future_schedule_preview"
  end

  # GET /recurring_driver_compliances/compliance_based_schedule_preview
  def compliance_based_schedule_preview
    generate_compliance_based_schedule_preview
    render partial: "compliance_based_schedule_preview"
  end
  
  # PUT /recurring_driver_compliances/generate
  def generate!
    # This is in place only for testing. In production we would rely on a cron 
    # task to generate these regularly
    raise ActionController::RoutingError if Rails.env.production? or Rails.env.staging?
    RecurringDriverCompliance.generate! date_range_length: 5.years
    redirect_to recurring_driver_compliances_url, notice: 'All recurring driver compliance events have been generated.'
  end  

  private

  # Only allow a trusted parameter "white list" through.
  def recurring_driver_compliance_params
    params.require(:recurring_driver_compliance).permit(
      :event_name,
      :event_notes,
      :recurrence_schedule,
      :recurrence_frequency,
      :recurrence_notes,
      :start_date,
      :future_start_rule,
      :future_start_schedule,
      :future_start_frequency,
      :compliance_based_scheduling,
    )
  end
  
  def generate_schedule_preview
    @schedule_preview = if @recurring_driver_compliance.compliance_based_scheduling?
      # Return the first start date
      [@recurring_driver_compliance.start_date]
    else
      # Return the first 6 occurrences, beginning with the start date
      RecurringDriverCompliance.occurrence_dates_on_schedule_in_range @recurring_driver_compliance, range_start_date: Date.current, range_end_date: (@recurring_driver_compliance.start_date + (@recurring_driver_compliance.recurrence_frequency * 5).send(@recurring_driver_compliance.recurrence_schedule))
    end.collect{ |date| date.to_s(:long) }
  end
  
  def generate_future_schedule_preview
    @future_schedule_preview = if @recurring_driver_compliance.compliance_based_scheduling?
      # Return the adjusted_start_date, as of the day after the start date
      [RecurringDriverCompliance.adjusted_start_date(@recurring_driver_compliance, as_of: @recurring_driver_compliance.start_date.tomorrow)]
    else
      # Return the first 6 occurrences, as of the day after the start date
      adjusted_start_date = RecurringDriverCompliance.adjusted_start_date(@recurring_driver_compliance, as_of: @recurring_driver_compliance.start_date.tomorrow)
      RecurringDriverCompliance.occurrence_dates_on_schedule_in_range @recurring_driver_compliance, first_date: adjusted_start_date, range_end_date: (adjusted_start_date + (@recurring_driver_compliance.recurrence_frequency * 5).send(@recurring_driver_compliance.recurrence_schedule))
    end.collect{ |date| date.to_s(:long) }
  end
  
  def generate_compliance_based_schedule_preview
    # Return the next occurance date, as of the day after the start date
    assumed_completion_date = @recurring_driver_compliance.start_date + 1.day
    @compliance_based_schedule_preview = [RecurringDriverCompliance.next_occurrence_date_from_previous_date_in_range(@recurring_driver_compliance, assumed_completion_date, range_end_date: (assumed_completion_date + @recurring_driver_compliance.recurrence_frequency.send(@recurring_driver_compliance.recurrence_schedule)))].collect{ |date| date.to_s(:long) }
  end
  
  def prep_form
    @readonly = @recurring_driver_compliance.driver_compliances.any?
  end
  
  def prep_preview
    @recurring_driver_compliance = RecurringDriverCompliance.new recurring_driver_compliance_params
  end
  
  def generate_schedule_previews
    if @recurring_driver_compliance.persisted? or @recurring_driver_compliance.valid?
      generate_schedule_preview
      generate_future_schedule_preview
      generate_compliance_based_schedule_preview if @recurring_driver_compliance.compliance_based_scheduling?
    end
  end
end
