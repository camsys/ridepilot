class Run < ActiveRecord::Base
  include RequiredFieldValidatorModule
  include RecurringRideCoordinator
  schedules_occurrences_with :repeating_run, 
    with_attributes: -> (run) {
      attrs = {}
      RepeatingRun.ride_coordinator_attributes.each {|attr| attrs[attr] = run.send(attr) }
      attrs['driver_id'] = run.repetition_driver_id
      attrs['vehicle_id'] = run.repetition_vehicle_id
      attrs['schedule_attributes'] = {
        repeat:        1,
        interval_unit: "week",
        start_date:    run.date.to_s,
        interval:      run.repetition_interval, 
        monday:        run.repeats_mondays    ? 1 : 0,
        tuesday:       run.repeats_tuesdays   ? 1 : 0,
        wednesday:     run.repeats_wednesdays ? 1 : 0,
        thursday:      run.repeats_thursdays  ? 1 : 0,
        friday:        run.repeats_fridays    ? 1 : 0,
        saturday:      run.repeats_saturdays  ? 1 : 0,
        sunday:        run.repeats_sundays    ? 1 : 0
      }
      attrs
    },
    destroy_future_occurrences_with: -> (run) {
      # Be sure not delete occurrences that have already been completed.
      if run.date < Date.today
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).after_today.incomplete.destroy_all
      else 
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).after(run.date).incomplete.destroy_all
      end
    },
    unlink_past_occurrences_with: -> (run) {
      if run.date < Date.today
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).today_and_prior.update_all "repeating_run_id = NULL"
      else 
        Run.where().not(id: run.id).repeating_based_on(run.repeating_run).prior_to(run.date).update_all "repeating_run_id = NULL"
      end
    }
  
  has_paper_trail
  
  # Ignores:
  #   Already required:
  #     date
  #     driver_id
  #     provider_id
  #     vehicle_id
  #   Already checked by set_complete:
  #     actual_end_time
  #     actual_start_time (by virtue of actual_end_time)
  #   Meta
  #     created_at
  #     updated_at
  #     lock_version
  FIELDS_FOR_COMPLETION = [
    :name, 
    :start_odometer, 
    :end_odometer, 
    :unpaid_driver_break_time, 
    :paid, 
  ].freeze
  
  belongs_to :provider
  belongs_to :driver
  belongs_to :vehicle, inverse_of: :runs

  has_many :trips, -> { order(:pickup_time) }, :dependent => :nullify

  accepts_nested_attributes_for :trips
  
  before_validation :fix_dates, :set_complete
  
  validates                 :name, presence: true
  validates                 :driver, presence: true
  validates                 :provider, presence: true
  validates                 :vehicle, presence: true
  validates_date            :date
  validates_datetime        :actual_start_time, allow_blank: true
  validates_datetime        :actual_end_time, after: :actual_start_time, allow_blank: true
  validates_datetime        :scheduled_start_time, allow_blank: true
  validates_datetime        :scheduled_end_time, after: :scheduled_start_time, allow_blank: true
  validates_numericality_of :start_odometer, allow_nil: true
  validates_numericality_of :end_odometer, allow_nil: true
  validates_numericality_of :end_odometer, greater_than: -> (run){ run.start_odometer }, less_than: -> (run){ run.start_odometer + 500 }, if: -> (run){ run.start_odometer.present? }, allow_nil: true
  validates_numericality_of :unpaid_driver_break_time, allow_nil: true
  # TODO discuss when to enable this:
  # validate                  :driver_availability
  
  scope :after,                  -> (date) { where('runs.date > ?', date) }
  scope :after_today,            -> { where('runs.date = ?', Date.today) }
  scope :for_date,               -> (date) { where('runs.date = ?', date) }
  scope :for_date_range,         -> (start_date, end_date) { where("runs.date >= ? and runs.date < ?", start_date, end_date) }
  scope :for_paid_driver,        -> { where(paid: true) }
  scope :for_provider,           -> (provider_id) { where(provider_id: provider_id) }
  scope :for_vehicle,            -> (vehicle_id) { where(vehicle_id: vehicle_id) }
  scope :for_volunteer_driver,   -> { where(paid: false) }
  scope :has_scheduled_time,     -> { where.not(scheduled_start_time: nil).where.not(scheduled_end_time: nil) }
  scope :incomplete,             -> { where(complete: false) }
  scope :incomplete_on,          -> (date) { incomplete.for_date(date) }
  scope :with_odometer_readings, -> { where("start_odometer IS NOT NULL and end_odometer IS NOT NULL") }
  scope :prior_to,               -> (date) { where('runs.date < ?', date) }
  scope :today_and_prior,        -> { where('runs.date <= ?', Date.today) }

  CAB_RUN_ID = -1 # id for cab runs 
  UNSCHEDULED_RUN_ID = -2 # id for unscheduled run (empty container)
  
  def cab=(value)
    @cab = value
  end

  def vehicle_name
    vehicle.name if vehicle.present?
  end
  
  def label
    if @cab
      "Cab"
    else
      !name.blank? ? name: "#{vehicle_name}: #{driver.try :name} #{scheduled_start_time.try :strftime, "%I:%M%P"}".gsub( /m$/, "" )
    end
  end
  
  def as_json(options)
    { :id => id, :label => label }
  end

  def as_calendar_json
    {
      id: id,
      start: scheduled_start_time ? scheduled_start_time.iso8601 : nil,
      end: scheduled_end_time ? scheduled_end_time.iso8601 : nil,
      title: label,
      resource: date.to_date.to_s(:js)
    }
  end

  def self.fake_cab_run
    Run.new name: TranslationEngine.translate_text(:cab), id: Run::CAB_RUN_ID
  end

  def self.fake_unscheduled_run
    Run.new name: TranslationEngine.translate_text(:unscheduled), id: Run::UNSCHEDULED_RUN_ID
  end

  private

  # A run is considered complete if:
  #  actual_end_time is valued (which requires that actual_start_time is also valued)
  #  actual_end_time is before "now"
  #  None of its trips are still considered pending
  #  Any fields that the run provider has listed as required are valued
  def set_complete
    self.complete = actual_end_time.present? && actual_end_time < Time.zone.now && trips.incomplete.empty? && check_provider_fields_required_for_run_completion
    true
  end

  def fix_dates
    d = self.date
    unless d.nil?
      unless scheduled_start_time.nil?
        s = scheduled_start_time 
        self.scheduled_start_time = Time.zone.local(d.year, d.month, d.day, s.hour, s.min, 0) 
        scheduled_start_time_will_change!
      end
      unless scheduled_end_time.nil?
        s = scheduled_end_time
        self.scheduled_end_time = Time.zone.local(d.year, d.month, d.day, s.hour, s.min, 0) 
        scheduled_end_time_will_change!
      end
      unless actual_start_time.nil?
        a = actual_start_time
        self.actual_start_time = Time.zone.local(d.year, d.month, d.day, a.hour, a.min, 0) 
        actual_start_time_will_change!
      end
      unless actual_end_time.nil?
        a = actual_end_time
        self.actual_end_time = Time.zone.local(d.year, d.month, d.day, a.hour, a.min, 0)
        actual_end_time_will_change!
      end
    end
    true
  end

  def driver_availability
    if date && scheduled_start_time && driver && !driver.available?(date.wday, scheduled_start_time.strftime('%H:%M'))
      errors.add(:driver_id, TranslationEngine.translate_text(:unavailable_at_run_time))
    end
  end
  
  def check_provider_fields_required_for_run_completion
    provider.present? && provider.fields_required_for_run_completion.select{ |attr| self[attr].blank? }.empty?
  end
end
