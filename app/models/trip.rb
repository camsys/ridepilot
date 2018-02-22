class Trip < ActiveRecord::Base
  include RequiredFieldValidatorModule
  include TripCore
  include PublicActivity::Common

  acts_as_paranoid # soft delete

  has_paper_trail

  attr_accessor :driver_id, :vehicle_id   #,:date #Custom date setter and getter in trip_core.rb

  belongs_to :called_back_by, -> { with_deleted }, class_name: "User"
  belongs_to :run
  belongs_to :trip_result, -> { with_deleted }
  has_one    :return_trip, class_name: "Trip", foreign_key: :linking_trip_id
  belongs_to :outbound_trip, class_name: 'Trip', foreign_key: :linking_trip_id
  belongs_to :repeating_trip
  has_one    :donation
  has_many   :ridership_mobilities, class_name: "TripRidershipMobility", foreign_key: :host_id, dependent: :destroy

  delegate :label, to: :run, prefix: :run, allow_nil: true
  delegate :code, :name, to: :trip_result, prefix: :trip_result, allow_nil: true

  validates :mileage, numericality: {greater_than: 0, allow_blank: true}
  validate :driver_is_valid_for_vehicle
  validate :completable_until_trip_appointment_day
  validate :provider_availability
  validate :return_trip_later_than_outbound_trip
  validate :within_advance_day_scheduling
  validate :customer_active
  validate :fit_run_schedule

  scope :after,              -> (pickup_time) { where('pickup_time > ?', pickup_time.utc) }
  scope :after_today,        -> { where('pickup_time > ?', Date.today.end_of_day) }
  scope :today_and_prior,    -> { where('pickup_time <= ?', Date.today.end_of_day) }
  scope :prior_to_today,     -> { where('pickup_time < ?', Date.today.beginning_of_day) }
  scope :during,             -> (pickup_time, appointment_time) { 
                                  where('NOT ((pickup_time < ? AND appointment_time < ?) OR (pickup_time > ? AND appointment_time > ?))', 
                                  pickup_time.utc, appointment_time.utc, pickup_time.utc, appointment_time.utc) }
  scope :for_date,           ->(date) { where(pickup_time: date.beginning_of_day..date.end_of_day) }
  scope :for_date_range,     -> (from_date, to_date) { where(pickup_time: from_date.beginning_of_day..to_date.end_of_day) } 
  scope :prior_to,           -> (pickup_time) { where('pickup_time < ?', pickup_time.to_datetime.in_time_zone.utc) } 
  scope :has_scheduled_time, -> { where.not(pickup_time: nil) }
  scope :by_result,          -> (code) { includes(:trip_result).references(:trip_result).where("trip_results.code = ?", code) }
  scope :called_back,        -> { where('called_back_at IS NOT NULL') }
  scope :completed,          -> { joins(:trip_result).where(trip_results: {code: 'COMP'}) }
  scope :for_driver,         -> (driver_id) { not_for_cab.where(runs: {driver_id: driver_id}).joins(:run) }
  scope :for_vehicle,        -> (vehicle_id) { not_for_cab.where(runs: {vehicle_id: vehicle_id}).joins(:run) }
  scope :incomplete,         -> { where(trip_result: nil) }
  scope :empty_or_completed, -> { includes(:trip_result).references(:trip_result).where("trips.trip_result_id is NULL or trip_results.code = 'COMP'") }
  scope :turned_down,        -> { joins(:trip_result).where(trip_results: {code: 'TD'}) }
  scope :repeating_based_on, ->(scheduler) { where(repeating_trip_id: scheduler.try(:id)) }
  scope :outbound,           ->() { where(direction: 'outbound') }
  scope :return,             ->() { where(direction: 'return') }
  scope :driver_notified,    -> { where(driver_notified: true) }
  scope :driver_not_notified,-> { where("driver_notified is NULL or driver_notified = ?", false) }

  scope :standby,            -> { where(is_stand_by: true) }
  scope :scheduled,          -> { where("cab = ? or run_id is not NULL", true) }
  scope :unscheduled,        -> { where(run_id: nil).where("is_stand_by is NULL or is_stand_by = ?", false).where("cab is NULL or cab = ?", false) }
  scope :scheduled_to_run,   -> { where.not(run_id: nil) }
  scope :for_cab,            -> { where(cab: true) }
  scope :not_for_cab,        -> { where("cab is NULL or cab = ?", false) }

  # List of attributes of which the change would affect the run
  ATTRIBUTES_CAN_DISRUPT_RUN = [
    'customer_id',
    'pickup_time',
    'appointment_time',
    'pickup_address_id',
    'dropoff_address_id'
  ]

  def self.attributes_can_disrupt_run
    ATTRIBUTES_CAN_DISRUPT_RUN
  end

  # Special date attr_reader sends back pickup/appointment time date, or instance var if present
  def date
    return @date if @date
    return pickup_time.to_date if pickup_time
    return appointment_time.to_date if appointment_time
    return nil
  end

  # Special date attr_writer sets @date instance variable. Accepts a Date object or a date string
  # This date is used in setting pickup and appointment time attributes
  def date=(date)
    return false if date.blank?
    @date = Date.parse(date.to_s)
    # Refresh pickup and appointment time with new date
    self.pickup_time = pickup_time #unless pickup_time.to_date == @date
    self.appointment_time = appointment_time #unless appointment_time.to_date == @date
  end

  # Takes a time and a date object, and returns a time object on the passed Date
  def time_on_date(t, d)
    return nil unless t
    return t unless d
    t = t.to_time.in_time_zone
    Time.zone.local(d.year, d.month, d.day, t.hour, t.min, 0) # parse as local time
  end

  def complete
    trip_result.try(:code) == 'COMP'
  end

  def pending
    trip_result.blank?
  end

  def cancel!
    update_attributes( trip_result: TripResult.find_by_code('CANC') )
  end

  def vehicle_id
    run ? run.vehicle_id : @vehicle_id
  end

  def driver_id
    @driver_id || run.try(:driver_id)
  end

  # When setting pickup_time, set with @date attribute if present
  def pickup_time=(datetime)
    write_attribute :pickup_time,
      time_on_date(format_datetime(datetime), date)
  end

  # When setting appointment_time, set with @date attribute if present
  def appointment_time=(datetime)
    new_appointment_time = datetime ? time_on_date(format_datetime(datetime), date) : nil
    write_attribute :appointment_time, new_appointment_time
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

  def adjusted_run_id
    cab ? Run::CAB_RUN_ID : (run_id ? run_id : Run::UNSCHEDULED_RUN_ID)
  end

  def as_calendar_json
    return if appointment_time && appointment_time < pickup_time
    
    {
      id: id,
      pickup_time: pickup_time.iso8601,
      appointment_time: appointment_time.try(:iso8601),
      title: customer_name + "\n" + pickup_address.try(:address_text).to_s,
      start: pickup_time.iso8601,
      "end": appointment_time ? appointment_time.iso8601 : date.end_of_day.iso8601,
      resource: pickup_time.to_date.to_s(:js)
    }
  end

  def as_run_event_json
    return if appointment_time && appointment_time < pickup_time

    {
      id: id,
      pickup_time: pickup_time.iso8601,
      appointment_time: appointment_time.try(:iso8601),
      start: pickup_time.iso8601,
      "end": appointment_time ? appointment_time.iso8601 : date.end_of_day.iso8601,
      title: customer_name + "\n" + pickup_address.try(:address_text).to_s,
      resource: adjusted_run_id
    }
  end

  def is_cancelled_or_turned_down?
    trip_result && (trip_result.cancelled? || trip_result.turned_down?)
  end

  # Is the trip result one of several codes that needs reason
  def result_need_reason?
    trip_result && TripResult.is_reason_needed?(trip_result.code)
  end

  def clone_for_future!
    cloned_trip = self.dup

    cloned_trip.pickup_time = nil
    cloned_trip.appointment_time = nil
    cloned_trip.trip_result = nil
    cloned_trip.result_reason = nil
    cloned_trip.customer_informed = false
    cloned_trip.called_back_by = nil
    cloned_trip.donation = nil
    cloned_trip.run = nil
    cloned_trip.cab = false
    cloned_trip.repeating_trip = nil
    cloned_trip.drive_distance = nil
    cloned_trip.outbound_trip = nil
    cloned_trip.direction = :outbound

    cloned_trip.ridership_mobilities = self.ridership_mobilities.has_capacity.collect{|m| m.dup}

    cloned_trip
  end

  def clone_for_return!(pickup_time_str = nil, appointment_time_str = nil)

    return_trip = self.dup 
    return_trip.direction = :return
    return_trip.pickup_address = self.dropoff_address
    return_trip.pickup_address_notes = self.dropoff_address_notes
    return_trip.dropoff_address = self.pickup_address
    return_trip.dropoff_address_notes = self.pickup_address_notes

    # Set date to outbound trip date, and assume pickup and appt time will be on that date
    return_trip.date = self.date
    return_trip.pickup_time = pickup_time_str
    return_trip.appointment_time = appointment_time_str

    return_trip.outbound_trip = self
    return_trip.repeating_trip = nil
    return_trip.drive_distance = nil
    return_trip.trip_result = nil
    return_trip.result_reason = nil

    return_trip.ridership_mobilities = self.ridership_mobilities.has_capacity.collect{|m| m.dup}

    return_trip
  end

  def clone_for_repeating_trip!
    daily_trip_clone = self.clone_for_future!
    repeating_trip = RepeatingTrip.new
    repeating_trip.attributes = daily_trip_clone.attributes.select{ |k, v| repeating_trip.attributes.keys.include? k.to_s }

    repeating_trip
  end

  def is_linked?
    (is_return? && outbound_trip) || (is_outbound? && return_trip)
  end

  def is_return?
    direction.try(:to_sym) == :return
  end

  def is_outbound?
    direction.try(:to_sym) == :outbound
  end

  def update_drive_distance!
    from_lat = pickup_address.try(:latitude)
    from_lon = pickup_address.try(:longitude)
    to_lat = dropoff_address.try(:latitude)
    to_lon = dropoff_address.try(:longitude)

    return unless from_lat && from_lon && to_lat && to_lon

    self.drive_distance = TripPlanner.new(from_lat, from_lon, to_lat, to_lon, pickup_time).get_drive_distance
    self.save
  end

  def as_profile_json
    {
      trip_id: id,
      pickup_time: pickup_time.try(:iso8601),
      dropoff_time: appointment_time.try(:iso8601),
      comments: notes,
      status: status_json
    }
  end

  def status_json
    if trip_result
      code = trip_result.code
      name = trip_result.name
      message = trip_result.full_description
    elsif run
      code = :scheduled
      name = 'Scheduled'
      message = TranslationEngine.translate_text(:trip_has_been_scheduled)
    elsif cab
      code = :scheduled_to_cab
      name = 'Scheduled to Cab'
      message = TranslationEngine.translate_text(:trip_has_been_scheduled_to_cab)
    else
      code = :requested
      name = 'Requested'
      message = TranslationEngine.translate_text(:trip_has_been_requested)
    end

    {
      code: code,
      name: name,
      message: message
    }
  end

  # potentially support multi-leg trips
  # need revisit when multi-leg is supported as direction field needs to be refactored
  def self.parse_leg_as_direction(leg)
    if leg.try(:to_s) == '2'
      :return
    else
      :outbound 
    end
  end

  # Mark scheduled trips (for past and today) as driver_notified
  def self.mark_past_scheduled_trips_as_driver_notified!
    self.today_and_prior.scheduled.not_for_cab.driver_not_notified.update_all(driver_notified: true)
  end

  # Move past trips in Standby queue to Unmet Need
  def self.move_prior_standby_to_unmet!
    self.prior_to_today.standby.move_to_unmet!
  end

  def self.move_to_unmet!
    unmet = TripResult.find_by_code('UNMET')
    self.where(provider: Provider.active.pluck(:id)).update_all(is_stand_by: false, trip_result_id: unmet.id) if unmet.present?
  end

  def scheduled?
    run.present? || cab
  end

  # check if any attribute change would disrupt a run
  def run_disrupted_by_trip_changes?
    disruption_attrs_changed = self.changes.keys & Trip.attributes_can_disrupt_run
    actual_changes = []

    if disruption_attrs_changed.any?
      actual_changes = disruption_attrs_changed
      # filter out the case when you changed a nil to 0, in this case, we don't think it's a change
      disruption_attrs_changed.each do |attr_key|
        prev_val = self.try("#{attr_key}_was")
        val = self.try(attr_key)
        next unless (prev_val.blank? || prev_val == 0) && (val.blank? || val == 0)
        actual_changes = actual_changes - [attr_key]
      end
    end

    actual_changes.any?
  end

  def unschedule_trip
    if self.run.present?
      self.run = nil
      self.save(validate: false)
    elsif provider && provider.cab_enabled? && self.cab
      self.cab = false
      self.save(validate: false)
    end
  end

  def update_donation(user, amount)
    return unless user && amount

    if self.donation
      self.donation.update_attributes(user: user, amount: amount)
    elsif self.id && self.customer
      self.donation = Donation.create(date: Time.current, user: user, customer: self.customer, trip: self, amount: amount)
      self.save
    end
  end

  def post_process_trip_result_changed!(user = nil)
    self.is_stand_by = false if self.trip_result.present?
    if self.is_cancelled_or_turned_down?
      TrackerActionLog.cancel_or_turn_down_trip(self, user) 
      
      unless TripResult::CANCEL_CODES_BUT_KEEP_RUN.include?(self.trip_result.code)
        if self.scheduled? 
          if self.run.present?
            run = self.run
            self.run = nil
            #TrackerActionLog.trips_removed_from_run(run, [self], user)
          elsif self.cab
            self.cab = false
          end
        end
      end
    end
    
    self.save(validate: false) if self.changed?
  end

  private

  def driver_is_valid_for_vehicle
    # This will error if a run was found or extended for this vehicle and time,
    # but the driver for the run is not the driver selected for the trip
    if self.run.try(:driver_id).present? && self.driver_id.present? && self.run.driver_id.to_i != self.driver_id.to_i
      errors.add(:driver_id, TranslationEngine.translate_text(:driver_is_valid_for_vehicle_validation_error))
    end
  end

  # Can only allow to set trip as complete until day of the trip
  def completable_until_trip_appointment_day
    if complete && Time.current < pickup_time.in_time_zone.beginning_of_day
      errors.add(:base, TranslationEngine.translate_text(:completable_until_trip_appointment_day_validation_error))
    end
  end

  def provider_availability
    if pickup_time && provider && !provider.available?(pickup_time.wday, pickup_time.strftime('%H:%M'))
      errors.add(:base, TranslationEngine.translate_text(:provider_not_available_for_trip))
    end
  end

  def return_trip_later_than_outbound_trip
    if is_linked?
      if is_outbound? && appointment_time
        errors.add(:base, TranslationEngine.translate_text(:outbound_trip_dropoff_time_no_later_than_return_trip_pickup_time)) if appointment_time > return_trip.pickup_time
      elsif is_return? && pickup_time && outbound_trip.appointment_time
        errors.add(:base, TranslationEngine.translate_text(:return_trip_pickup_time_no_earlier_than_outbound_trip_dropoff_time)) if pickup_time < outbound_trip.appointment_time
      end
    end
  end

  # Formats a variety of inputs as a Time object, and catches errors.
  # If a time string (e.g. "10:00 AM") is sent along with a date param, will
  # create the time at the given date. Defaults to today.
  def format_datetime(datetime)
    if datetime.is_a?(String)
      begin
        Time.zone.parse(datetime.gsub(/\b(a|p)\b/i, '\1m').upcase)
      rescue
        nil
      end
    else
      datetime
    end
  end

  def within_advance_day_scheduling
    advance_day_scheduling = provider.try(:get_advance_day_scheduling)
    if date && advance_day_scheduling.present? && (date - Date.current).to_i > advance_day_scheduling
      errors.add(:date, TranslationEngine.translate_text(:beyond_advance_day_scheduling) % {advance_day_scheduling: advance_day_scheduling})
    end
  end

  def customer_active
    if customer && date && !customer.active_for_date?(date)
      errors.add(:customer, TranslationEngine.translate_text(:customer_inactive_for_trip_date)) 
    end
  end

  def fit_run_schedule
    if run 
      run_start_time = run.scheduled_start_time
      run_end_time = run.scheduled_end_time

      if run_start_time && run_end_time && pickup_time
        is_valid = (time_portion(self.pickup_time) >= time_portion(run_start_time)) && 
        (self.appointment_time.nil? || time_portion(self.appointment_time) <= time_portion(run_end_time))

        errors.add(:base, TranslationEngine.translate_text(:not_fit_in_run_schedule)) unless is_valid
      end
    end
  end

  def time_portion(time)
    (time - time.beginning_of_day) if time
  end
end
