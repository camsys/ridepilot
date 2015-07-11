class Trip < ActiveRecord::Base
  attr_accessor :driver_id, :vehicle_id, :via_repeating_trip

  belongs_to :provider
  belongs_to :run
  belongs_to :customer
  belongs_to :funding_source
  belongs_to :mobility
  belongs_to :pickup_address, :class_name=>"Address"
  belongs_to :dropoff_address, :class_name=>"Address"
  belongs_to :called_back_by, :class_name=>"User"
  belongs_to :repeating_trip

  belongs_to :trip_purpose
  delegate :name, to: :trip_purpose, prefix: :trip_purpose, allow_nil: true

  belongs_to :trip_result
  delegate :code, :name, to: :trip_result, prefix: :trip_result, allow_nil: true

  belongs_to :service_level
  delegate :name, to: :service_level, prefix: :service_level, allow_nil: true

  before_validation :compute_run
  before_create :create_repeating_trip
  before_update :update_repeating_trip
  after_save    :instantiate_repeating_trips
  
  serialize :guests

  validates_presence_of :customer
  validates_presence_of :pickup_address,   :unless => :allow_addressless_trip?
  validates_presence_of :dropoff_address,  :unless => :allow_addressless_trip?
  validates_presence_of :pickup_time,      :unless => :allow_addressless_trip?
  validates_presence_of :appointment_time, :unless => :allow_addressless_trip?
  validates_presence_of :trip_purpose_id
  validate :driver_is_valid_for_vehicle
  validates_associated :customer
  validates_associated :pickup_address
  validates_associated :dropoff_address
  validates_numericality_of :guest_count, :greater_than_or_equal_to => 0
  validates_numericality_of :attendant_count, :greater_than_or_equal_to => 0
  validates_numericality_of :mileage, :greater_than => 0, :allow_blank => true
  accepts_nested_attributes_for :customer # TODO make sure these are accounted for in Strong Param setup

  has_paper_trail
  
  scope :for_cab,            -> { where(:cab => true) }
  scope :not_for_cab,        -> { where(:cab => false) }
  scope :for_provider,       -> (provider_id) { where( :provider_id => provider_id ) }
  scope :for_date,           -> (date) { where('trips.pickup_time >= ? AND trips.pickup_time < ?', date.to_datetime.in_time_zone.utc, date.to_datetime.in_time_zone.utc + 1.day) }
  scope :for_date_range,     -> (start_date, end_date) { where('trips.pickup_time >= ? AND trips.pickup_time < ?', start_date.to_datetime.in_time_zone.utc, end_date.to_datetime.in_time_zone.utc) }
  scope :for_driver,         -> (driver_id) { not_for_cab.where(:runs => {:driver_id => driver_id}).joins(:run) }
  scope :for_vehicle,        -> (vehicle_id) { not_for_cab.where(:runs => {:vehicle_id => vehicle_id}).joins(:run) }
  scope :by_result,          -> (code) { includes(:trip_result).references(:trip_result).where("trip_results.code = ?", code) }
  scope :scheduled,          -> { includes(:trip_result).references(:trip_result).where("trips.trip_result_id is NULL or trip_results.code = 'COMP'") }
  scope :completed,          -> { Trip.by_result('COMP') }
  scope :turned_down,        -> { Trip.by_result('TD') }
  scope :by_service_level,   -> (level) { includes(:service_level).references(:service_level).where("service_levels.name = ?", level) }
  scope :today_and_prior,    -> { where('CAST(trips.pickup_time AS date) <= ?', Date.today.in_time_zone.utc) }
  scope :after_today,        -> { where('CAST(trips.pickup_time AS date) > ?', Date.today.in_time_zone.utc) }
  scope :prior_to,           -> (pickup_time) { where('trips.pickup_time < ?', pickup_time.to_datetime.in_time_zone.utc) }
  scope :after,              -> (pickup_time) { where('trips.pickup_time > ?', pickup_time.utc) }
  scope :repeating_based_on, -> (repeating_trip) { where(:repeating_trip_id => repeating_trip.id) }
  scope :called_back,        -> { where('called_back_at IS NOT NULL') }
  scope :not_called_back,    -> { where('called_back_at IS NULL') }
  scope :individual,         -> { joins(:customer).where(:customers => {:group => false}) }

  DAYS_OF_WEEK = %w{monday tuesday wednesday thursday friday saturday sunday}
  
  DAYS_OF_WEEK.each do |day|
    define_method "repeats_#{day}s=" do |value|
      instance_variable_set "@repeats_#{day}s", (value == "1" || value == true)
    end

    define_method "repeats_#{day}s" do
      if instance_variable_get("@repeats_#{day}s").nil?
        if repeating_trip.present?
          instance_variable_set "@repeats_#{day}s", repeating_trip.schedule_attributes.send(day) == 1
        else
          instance_variable_set "@repeats_#{day}s", false 
        end
      else
        instance_variable_get("@repeats_#{day}s")
      end
    end
  end

  def date
    pickup_time.to_date
  end

  def complete
    trip_result.try(:code) == 'COMP'
  end

  def pending
    trip_result.blank?
  end

  def vehicle_id
    run ? run.vehicle_id : @vehicle_id
  end

  def driver_id
    @driver_id || run.try(:driver_id)
  end
  
  def pickup_time=(datetime)
    write_attribute :pickup_time, format_datetime( datetime ) 
  end
  
  def appointment_time=(datetime)
    write_attribute :appointment_time, format_datetime( datetime )
  end

  def run_text
    if cab
      "Cab"
    elsif run
      run.label
    else
      "(No run specified)"
    end
  end

  def trip_count
    if customer.group
      count = group_size
    else 
      count = guest_count + attendant_count + 1
    end
    round_trip ? count * 2 : count
  end

  def repetition_driver_id=(value)
    @repetition_driver_id = (value.blank? ? nil : value.to_i)
  end

  def repetition_driver_id
    if @repetition_driver_id.nil?
      @repetition_driver_id = repeating_trip.try :driver_id
    else
      @repetition_driver_id
    end
  end

  def repetition_vehicle_id=(value)
    @repetition_vehicle_id = (value.blank? ? nil : value.to_i)
  end

  def repetition_vehicle_id
    if @repetition_vehicle_id.nil?
      @repetition_vehicle_id = repeating_trip.try :vehicle_id
    else
      @repetition_vehicle_id
    end
  end

  def repetition_customer_informed=(value)
    @repetition_customer_informed = (value == "1" || value == true)
  end

  def repetition_customer_informed
    if @repetition_customer_informed.nil?
      @repetition_customer_informed = repeating_trip.try :customer_informed
    else
      @repetition_customer_informed
    end
  end

  def repetition_interval=(value)
    @repetition_interval = value.to_i
  end

  def repetition_interval
    if @repetition_interval.nil?
      if repeating_trip.present?
        @repetition_interval = repeating_trip.schedule_attributes.interval 
      else
        1
      end
    else
      @repetition_interval
    end
  end

  def is_repeating_trip?
    ((repetition_interval || 0) > 0 && (
      repeats_mondays     || 
      repeats_tuesdays    || 
      repeats_wednesdays  || 
      repeats_thursdays   || 
      repeats_fridays     || 
      repeats_saturdays   || 
      repeats_sundays
      ))
  end

  def is_in_district?
    pickup_address.try(:in_district) && dropoff_address.try(:in_district)
  end
  
  def allow_addressless_trip?
    # The provider_id is assigned via the customer. If the customer isn't present,
    # then the whole trip is invalid. So in that case, ignore the address errors
    # until there is a customer.
    (customer.blank? || customer.id.blank? || (provider.present? && provider.allow_trip_entry_from_runs_page)) && run.present?
  end
    
private
  
  def create_repeating_trip
    if is_repeating_trip? && !via_repeating_trip
      self.repeating_trip = RepeatingTrip.create!(repeating_trip_attributes)
    end
  end

  def update_repeating_trip
    if is_repeating_trip? 
      #this is a repeating trip, so we need to edit both
      #the repeating trip, and the instance for today
      if repeating_trip.blank?
        create_repeating_trip
      else
        repeating_trip.attributes = repeating_trip_attributes
        if repeating_trip.changed?
          repeating_trip.save!
          destroy_future_repeating_trips
        end
      end
    elsif !is_repeating_trip? && repeating_trip.present?
      destroy_future_repeating_trips
      unlink_past_trips
      rt = repeating_trip
      self.repeating_trip_id = nil
      rt.destroy
    end
  end

  def instantiate_repeating_trips
    repeating_trip.instantiate if !repeating_trip_id.nil? && !via_repeating_trip
  end

  def destroy_future_repeating_trips
    if pickup_time < Time.now #Be sure not delete trips that have already happened.
      Trip.repeating_based_on(repeating_trip).after_today.not_called_back.destroy_all
    else 
      Trip.repeating_based_on(repeating_trip).after(pickup_time).not_called_back.destroy_all
    end
  end

  def unlink_past_trips
    if pickup_time < Time.now 
      Trip.repeating_based_on(repeating_trip).today_and_prior.update_all 'repeating_trip_id = NULL'
    else 
      Trip.repeating_based_on(repeating_trip).prior_to(pickup_time).update_all 'repeating_trip_id = NULL'
    end
  end

  def repeating_trip_attributes
    attrs = {}
    RepeatingTrip.trip_attributes.each {|attr| attrs[attr] = self.send(attr) }
    attrs['driver_id'] = repetition_driver_id
    attrs['vehicle_id'] = repetition_vehicle_id
    attrs['customer_informed'] = repetition_customer_informed
    attrs['schedule_attributes'] = {
      :repeat        => 1,
      :interval_unit => "week", 
      :start_date    => pickup_time.to_date.to_s,
      :interval      => repetition_interval, 
      :monday        => repeats_mondays    ? 1 : 0,
      :tuesday       => repeats_tuesdays   ? 1 : 0,
      :wednesday     => repeats_wednesdays ? 1 : 0,
      :thursday      => repeats_thursdays  ? 1 : 0,
      :friday        => repeats_fridays    ? 1 : 0,
      :saturday      => repeats_saturdays  ? 1 : 0,
      :sunday        => repeats_sundays    ? 1 : 0
    }
    attrs
  end

  def format_datetime(datetime)
    if datetime.is_a?( String ) 
      Time.zone.parse(datetime.gsub(/\b(a|p)\b/i, '\1m').upcase)
    elsif datetime.present?
      datetime
    else
      nil
    end
  end

  def driver_is_valid_for_vehicle
    # This will error if a run was found or extended for this vehicle and time, 
    # but the driver for the run is not the driver selected for the trip
    if self.run.try(:driver_id).present? && self.driver_id.present? && self.run.driver_id.to_i != self.driver_id.to_i
      errors[:driver_id] << "is not the driver for the selected vehicle during this vehicle's run."
    end
  end

  def compute_run    
    return if run_id || cab || vehicle_id.blank? || provider_id.blank?

    if !pickup_time or !appointment_time 
      return #we'll error out in validation
    end

    #when the trip is saved, we need to find or create a run for it.
    #this will depend on the driver and vehicle.  
    self.run = Run.where("scheduled_start_time <= ? and scheduled_end_time >= ? and vehicle_id=? and provider_id=?", pickup_time, appointment_time, vehicle_id, provider_id).first

    if run.nil?
      #find the next/previous runs for this vehicle and, if necessary,
      #split or change times on them

      previous_run = Run.where("scheduled_start_time <= ? and vehicle_id=? and provider_id=? ", appointment_time, vehicle_id, provider_id).order("scheduled_start_time").last

      next_run = Run.where("scheduled_start_time >= ? and vehicle_id=? and provider_id=? ", pickup_time, vehicle_id, provider_id).order("scheduled_start_time").first

      #there are four possible cases: either the previous or the next run
      #could overlap the trip, or neither could.

      if previous_run and previous_run.scheduled_end_time > pickup_time
        #previous run overlaps trip
        if next_run and next_run.scheduled_start_time < appointment_time
          #next run overlaps trip too
          return handle_overlapping_runs(previous_run, next_run)
        else
          #just the previous run
          if previous_run.scheduled_start_time.to_date != pickup_time.to_date
            self.run = make_run
          else
            self.run = previous_run
            previous_run.update_attributes! :scheduled_end_time => run.appointment_time
          end
        end
      else
        if next_run and next_run.scheduled_start_time < appointment_time
          #just the next run
          if next_run.scheduled_start_time.to_date != pickup_time.to_date
            self.run = make_run
          else
            self.run = next_run
            next_run.update_attributes! :scheduled_start_time => run.pickup_time
          end
        else
          #no overlap, create a new run
          self.run = make_run
        end
      end
    end

  end

  def handle_overlapping_runs(previous_run, next_run)
    #can we unify the runs?
    if next_run.driver_id == previous_run.driver_id
      self.run = unify_runs(previous_run, next_run)
      return
    end

    #now, can we push the start of the second run later?
    first_trip = next_run.trips.first
    if first_trip.scheduled_start_time > appointment_time
      #yes, we can
      next_run.update_attributes! :scheduled_start_time => appointment_time
      previous_run.update_attributes! :scheduled_end_time => appointment_time
      self.run = previous_run
    else
      #no, the second run is fixed. Can we push the end of the
      #first run earlier?
      last_trip = previous_run.trips.last
      if last_trip.scheduled_end_time <= pickup_time
        #yes, we can
        previous_run.update_attributes! :scheduled_end_time => pickup_time
        next_run.update_attributes! :scheduled_start_time => appointment_time
        self.run = next_run
      else
        return false
      end
    end
  end

  def unify_runs(before, after)
    before.update_attributes! :scheduled_end_time => after.scheduled_end_time, :end_odometer => after.end_odometer
    for trip in after.trips
      trip.run = before
    end
    after.destroy
    return before
  end

  def make_run
    Run.create({
      :provider_id          => provider_id,
      :date                 => pickup_time.to_date,
      :scheduled_start_time => Time.zone.local(pickup_time.year,
                                               pickup_time.month,
                                               pickup_time.day,
                                               BUSINESS_HOURS[:start],
                                               0, 0),
      :scheduled_end_time   => Time.zone.local(pickup_time.year,
                                               pickup_time.month,
                                               pickup_time.day,
                                               BUSINESS_HOURS[:end],
                                               0, 0),
      :vehicle_id           => vehicle_id,
      :driver_id            => driver_id,
      :complete             => false,
      :paid                 => true
    })
  end

end
