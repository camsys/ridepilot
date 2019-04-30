class Run < ApplicationRecord
  include RequiredFieldValidatorModule
  include RunCore
  include PublicActivity::Common

  acts_as_paranoid # soft delete

  has_paper_trail

  serialize :manifest_order, Array

  FIELDS_FOR_COMPLETION = [
    :unpaid_driver_break_time,
    :paid,
  ].freeze
  
  BATCH_ACTIONS = [
    :cancel,
    :delete
  ].freeze

  has_many :trips, -> { order(:pickup_time) }, :dependent => :nullify
  has_many :itineraries, :dependent => :destroy
  has_many :public_itineraries, -> { order(:sequence) }, :dependent => :destroy

  belongs_to :repeating_run

  has_one :run_distance

  has_many :run_vehicle_inspections, dependent: :destroy
  has_many :vehicle_inspections, through: :run_vehicle_inspections

  belongs_to :from_garage_address, -> { with_deleted }, class_name: 'GarageAddress', foreign_key: 'from_garage_address_id'
  accepts_nested_attributes_for :from_garage_address, update_only: true
  belongs_to :to_garage_address, -> { with_deleted }, class_name: 'GarageAddress', foreign_key: 'to_garage_address_id'
  accepts_nested_attributes_for :to_garage_address, update_only: true

  accepts_nested_attributes_for :trips

  before_validation :fix_dates
  before_update :check_vehicle_change
  before_update :check_manifest_change
  after_create :add_init_run_itineraries
  after_update :apply_manifest_changes

  validate                  :name_uniqueness
  normalize_attribute :name, :with => [ :strip ]
  
  validates_date            :date
  validates_datetime        :actual_start_time, allow_blank: true
  validates_datetime        :actual_end_time, after: :actual_start_time, allow_blank: true
  validates_numericality_of :start_odometer, allow_nil: true
  validates_numericality_of :end_odometer, allow_nil: true
  validates_numericality_of :end_odometer, greater_than: -> (run){ run.start_odometer }, less_than: -> (run){ run.start_odometer + 500 }, if: -> (run){ run.start_odometer.present? }, allow_nil: true
  validates_numericality_of :unpaid_driver_break_time, allow_nil: true
  validate                  :within_advance_day_scheduling
  validate                  :driver_availability
  validate                  :vehicle_availability

  scope :after,                  -> (date) { where('runs.date > ?', date) }
  scope :after_today,            -> { where('runs.date > ?', Date.today) }
  scope :today_and_future,       -> { where('runs.date >= ?', Date.today) }
  scope :prior_to,               -> (date) { where('runs.date < ?', date) }
  scope :today_and_prior,        -> { where('runs.date <= ?', Date.today) }
  scope :for_date,               -> (date) { where(date: date) }
  scope :for_date_range,         -> (start_date, end_date) { where("runs.date >= ? and runs.date < ?", start_date, end_date) }
  scope :overlapped,             -> (run) { for_date(run.date).time_overlaps_with(run.scheduled_start_time, run.scheduled_end_time) }
  scope :this_week,              -> {
    where(date: DateTime.now.in_time_zone.beginning_of_week.to_date..DateTime.now.in_time_zone.end_of_week.to_date)
  }
  # Daily runs which conflict with another Repeating Run's schedule
  scope :conflicts_with_schedule, -> (repeating_run) do
    not_a_child_of(repeating_run)
    .select {|r| repeating_run.date_in_active_range?(r.date) && repeating_run.schedule.occurs_on?(r.date)}
  end

  scope :complete,               -> { where(complete: true) }
  scope :incomplete,             -> { where('complete is NULL or complete = ?', false) }
  scope :incomplete_on,          -> (date) { incomplete.for_date(date) }
  scope :with_odometer_readings, -> { where("start_odometer IS NOT NULL and end_odometer IS NOT NULL") }
  scope :repeating_based_on,     ->(scheduler) { where(repeating_run_id: scheduler.try(:id)) }
  scope :other_than,             -> (run) { run.new_record? ? all : where.not(id: run.id) }
  scope :not_a_child_of,         -> (repeating_run) { where.not(repeating_run_id: [repeating_run.id].compact) }
  scope :daily,                  -> {where(repeating_run_id: nil)}
  scope :recurring,              -> {where.not(repeating_run_id: nil)}
  scope :cancelled,              -> {where(cancelled: true)}
  scope :not_cancelled,          -> {where('cancelled is NULL or cancelled = ?', false)}

  scope :other_overlapped_runs, -> (run) { overlapped(run).other_than(run) }

  scope :default_order, -> { order(:date, :scheduled_start_time_string, :scheduled_end_time_string, :name) }

  CAB_RUN_ID = -1 # id for cab runs
  UNSCHEDULED_RUN_ID = -2 # id for unscheduled run (empty container)
  STANDBY_RUN_ID = -3 # standby queue id
  TRIP_UNMET_NEED_ID = -4 # put trip to unmet need
  
  # based on recurring dispatching, batch assign recurring trip instances to recurring run instances
  def self.batch_update_recurring_trip_assignment!
    recurring.each do |r|      
      r.update_recurring_trip_assignment! if r
    end
  end

  # based on recurring dispatching, assign recurring trip instances to recurring run instances
  def update_recurring_trip_assignment!
    return unless self.date && 
      (self.manifest_order.blank? || (self.manifest_order - ["run_begin","run_end"]).empty?) && 
      self.itineraries.revenue.empty?

    day_of_week = self.date.wday
    rr = self.repeating_run
    return if !rr.present? || rr.weekday_assignments.for_wday(day_of_week).empty?

    rr_manifest_order = rr.repeating_run_manifest_orders.for_wday(day_of_week).first.try(:manifest_order) || []
  
    run_manifest_order = []

    if rr_manifest_order.any?
      rr_manifest_order.each do |mo|
        next if mo.blank?
        # mo format: "trip_{trip_id}_leg_{leg_id}", e.g., "trip_14_leg_!"
        mo_pieces = mo.split('_')
        # get recurring trip id
        rtrip_id = mo_pieces[1].try(:to_i)

        # get recurring trip
        rtrip = RepeatingTrip.find_by_id(rtrip_id)
        next unless rtrip.present?

        # get trip instance for run date
        trip = rtrip.trips.for_date(date).first

        next unless trip.present?

        # make a copy and update run manifest order
        new_mo_pieces = mo_pieces.dup
        new_mo_pieces[1] = trip.id
        run_manifest_order << new_mo_pieces.join("_")

        unless trip.run_id.present?
          # assign trip to run
          trip.run = self
          trip.save(validate: false)
        end
      end
    else
      rr_weekday_assignments = rr.weekday_assignments.for_wday(day_of_week)
      if rr_weekday_assignments.any?
        rr_weekday_assignments.each do |assignment|
          rtrip = assignment.repeating_trip
          next unless rtrip.present?

          # get trip instance for run date
          trip = rtrip.trips.for_date(date).first
          next unless trip.present?

          unless trip.run_id.present?
            # assign trip to run
            trip.run = self
            trip.save(validate: false)

            self.add_trip_manifest!(trip.id)
          end
        end
      end
    end

    self.manifest_changed = true
    run_manifest_order = add_run_begin_end_order(run_manifest_order)
    if run_manifest_order.any?
      self.manifest_order = run_manifest_order 
    end

    self.save(validate: false) if self.changed?

    # create itineraries
    reset_itineraries
    # publish manifest
    if self.manifest_publishable?
      RunStatsCalculator.new(self.id).process_eta
      self.publish_manifest!
    end
  end

  # make manifest public
  def publish_manifest!(notify_driver = false)
    old_public_itins = self.public_itineraries
    finished_itins = old_public_itins.finished
    non_finished_itins = old_public_itins.non_finished

    last_finished_itin = finished_itins.last.try(:itinerary)
    new_itins = self.sorted_itineraries
    last_finished_itin_idx = new_itins.index(last_finished_itin) || -1

    first_non_finished_public_itin = non_finished_itins.first
    first_non_finished_itin = first_non_finished_public_itin.try(:itinerary)
    first_non_finished_itin_eta = first_non_finished_public_itin.try(:eta)

    # keep finished ones
    self.public_itineraries = finished_itins
    public_itin_count = finished_itins.size

    # process non-finished ones
    first_non_finished_internal_itin = nil
    self.sorted_itineraries[last_finished_itin_idx+1..-1].each do |itin|
      next if itin.finish_time
      itin_eta = itin.eta 

      # check if active itin has changed, e.g., dispatcher moved a new trip before current active itin
      # if not changed, need to copy departure_time etc to new itin
      if !first_non_finished_internal_itin
        first_non_finished_internal_itin = itin
        # check if first_non_finished_itin departed or not
        if first_non_finished_itin && first_non_finished_itin.departure_time
          if itin.itin_id == first_non_finished_itin.itin_id
            itin.copyAvlDataFrom!(first_non_finished_itin)
            itin_eta = first_non_finished_itin_eta
          else
            # means previous active itin is not active, new itin is inserted before it
            # therefore, need to clear previous active itin's departure_time 
            first_non_finished_itin.reset!
          end
        end
      end

      self.public_itineraries.new(run: self, itinerary: itin, sequence: public_itin_count, eta: itin_eta).save
      public_itin_count += 1
    end
    self.save(validate: false)
    
    # update publish time
    self.manifest_published_at = DateTime.now
    self.manifest_changed = false
    self.save(validate: false)

    if notify_driver
      ManifestNotificationWorker.perform_async(self.id)
    end
  end

  def manifest_publishable?
    self.driver.present? && # has driver
      self.vehicle.present? &&  # has vehicle
      (
        (self.from_garage_address && self.to_garage_address) || # has start & end locations
        self.vehicle.garage_address # or vehicle has garage address
      ).present?  
  end

  def manifest_unpublishable_reasons
    reasons = []
    unless self.driver 
      reasons << "no driver"
    end
    unless self.vehicle 
      reasons << "no vehicle"
    end

    unless ((self.from_garage_address && self.to_garage_address) || self.vehicle.garage_address )
      reasons << "no run start/end location(s)"
    end

    reasons
  end

  # "Cancels" a run: mark as cancelled and unschedule everything
  def cancel!
    self.cancelled = true
    unschedule!
  end

  # unschedule trips
  def unschedule!(auto_save = true)
    self.manifest_order = nil
    self.save(validate: false) if auto_save
    
    trips.clear # Doesn't actually destroy the records, just removes the association
    itineraries.destroy_all
  end
  
  # Cancels all runs in the collection, returning the count of trips removed from runs
  def self.cancel_all
    cancelable_runs = self.where(actual_start_time: nil)
    cancelable_runs.update_all(manifest_order: nil)

    run_ids = cancelable_runs.pluck(:id)
    Trip.where(run_id: run_ids).update_all(run_id: nil)
    Itinerary.where(run_id: run_ids).destroy_all
  end

  def add_trip_manifest!(trip_id)
    # remove it first in case same trip record was left previously
    delete_trip_manifest!(trip_id)

    #scan from the beginning to injert based on scheduled_pickup_time
    trip = Trip.find_by_id trip_id
    if trip
      trip_pickup_time = trip.pickup_time
      trip_appt_time = trip.appointment_time
      pickup_index = nil 
      appt_index = nil

      finished_itin_data = self.itineraries.revenue.finished.pluck(:trip_id, :leg_flag)
      manifest_order_array = self.manifest_order
      manifest_order_array.each_with_index do |leg_name, index|
        leg_name_parts = leg_name.split('_')
        leg_trip_id = leg_name_parts[1]
        leg_flag = leg_name_parts[3].to_i
        is_pickup = leg_flag == 1

        # move to next if current itin is finished
        next if  finished_itin_data.include?([leg_trip_id, leg_flag])

        a_trip = Trip.find_by_id leg_trip_id
        if a_trip 
          action_time = is_pickup ? a_trip.pickup_time : a_trip.appointment_time
          
          next unless action_time

          pickup_index = index if !pickup_index && action_time.to_s(:time_utc) > trip_pickup_time.to_s(:time_utc)

          if !appt_index
            if trip_appt_time
              appt_index = index if action_time.to_s(:time_utc) > trip_appt_time.to_s(:time_utc)
              appt_index += 1 if pickup_index && pickup_index == appt_index
            else
              appt_index = pickup_index + 1 if pickup_index
            end
          end

          break if pickup_index && appt_index
        end
      end

      is_run_end_included = manifest_order_array.last == 'run_end'
      last_itin_spot = is_run_end_included ? (manifest_order_array.size - 1) : manifest_order_array.size
      
      is_pickup_included = manifest_order_array.include?("trip_#{trip_id}_leg_1")
      is_dropoff_included = manifest_order_array.include?("trip_#{trip_id}_leg_2")

      if (!pickup_index && !is_pickup_included)
        pickup_index = last_itin_spot
        appt_index = last_itin_spot + 1
      elsif !appt_index && !is_dropoff_included
        if is_pickup_included
          appt_index = manifest_order_array.index("trip_#{trip_id}_leg_1") + 1
        else
          appt_index = last_itin_spot + 1
        end
      end

      # Injert at certain index
      unless is_pickup_included
        manifest_order_array.insert pickup_index, "trip_#{trip_id}_leg_1" if pickup_index && pickup_index <= manifest_order_array.size
      end
      unless is_dropoff_included
        manifest_order_array.insert appt_index, "trip_#{trip_id}_leg_2" if appt_index && appt_index <= manifest_order_array.size
      end
      self.manifest_order = manifest_order_array
      self.save(validate: false)
    end

    add_trip_itineraries!(trip_id)
  end

  def delete_trip_manifest!(trip_id)
    unless self.manifest_order.blank? 
      unfinished_trip_itin_flags = self.itineraries.where(trip_id: trip_id).where(finish_time: nil).pluck(:leg_flag)
      if unfinished_trip_itin_flags.include?(1)
        self.manifest_order.delete "trip_#{trip_id}_leg_1"
      end

      if unfinished_trip_itin_flags.include?(2)
        self.manifest_order.delete "trip_#{trip_id}_leg_2"
      end

      self.save(validate: false) if self.changed?
    end

    remove_trip_itineraries!(trip_id)
  end

  # given assigned trips, re-create all itineraries
  def reset_itineraries
    self.itineraries.destroy_all

    Itinerary.transaction do
      self.itineraries << build_begin_run_itinerary
      self.trips.each do |trip|
        self.itineraries << build_itinerary(trip.pickup_time, trip.pickup_address, trip.id, 1)
        self.itineraries << build_itinerary(trip.appointment_time, trip.dropoff_address, trip.id, 2)
      end
      self.itineraries << build_end_run_itinerary
    end
  end

  def sorted_itineraries(revenue_only = false)
    reset_itineraries if self.itineraries.empty?

    itins = itineraries
    itins = itins.revenue if revenue_only

    # exclude non_dispatchable legs
    exclude_leg_ids = itins.dropoff.joins(trip: :trip_result).where(trip_results: {code: TripResult::NON_DISPATCHABLE_CODES}).pluck(:id).uniq
    itins = itins.where.not(id: exclude_leg_ids) if exclude_leg_ids.any?

    run_manifest_order = manifest_order
    if run_manifest_order.blank?
      itins = itins.sort_by { |itin| [itin.time_diff, itin.leg_flag] }
    else
      run_manifest_order = add_run_begin_end_order(run_manifest_order)

      itins = itins.sort_by{|itin| 
        idx = run_manifest_order.index(itin.itin_id)
        [idx ? 0: 1, idx]
      }
    end

    itins
  end

  def add_run_begin_end_order(manifest_order = [])
    manifest_order ||= []
    manifest_order.insert(0, "run_begin") if manifest_order.first != 'run_begin'
    manifest_order << "run_end" if manifest_order.last != 'run_end'

    manifest_order
  end

  def build_begin_run_itinerary
    from_garage_address = self.from_garage_address || self.vehicle.try(:garage_address)
    build_itinerary(self.scheduled_start_time, from_garage_address, nil, 0)
  end

  def build_end_run_itinerary
    to_garage_address = self.to_garage_address || self.vehicle.try(:garage_address)
    build_itinerary(self.scheduled_end_time, to_garage_address, nil, 3)
  end

  # scheduled_time, address, trip, flag
  def build_itinerary(scheduled_time, address, trip_id, leg_flag)
    Itinerary.new(time: scheduled_time, address: address, run: self, trip_id: trip_id, leg_flag: leg_flag)
  end

  def add_trip_itineraries!(trip_id)
    trip = Trip.find_by_id(trip_id) 
    if trip 
      itin_id_flags = self.itineraries.pluck(:trip_id, :leg_flag)
      unless itin_id_flags.include?([trip_id, 1])
        is_changed = true
        build_itinerary(trip.pickup_time, trip.pickup_address, trip_id, 1).save
      end
      unless itin_id_flags.include?([trip_id, 2])
        is_changed = true
        build_itinerary(trip.appointment_time, trip.dropoff_address, trip_id, 2).save
      end

      self.itineraries.clear_times! if is_changed #clear other itins times
    end
  end

  def remove_trip_itineraries!(trip_id)
    trip_itins = self.itineraries.where(finish_time: nil).where(trip_id: trip_id)
    if trip_itins.any?
      trip_itins.destroy_all
      self.itineraries.clear_times! #clear other itins times
    end
  end

  def as_calendar_json
    {
      id: id,
      start: scheduled_start_time ? scheduled_start_time.iso8601 : nil,
      end: scheduled_end_time ? scheduled_end_time.iso8601 : nil,
      title: label,
      resource: date.to_date.to_s(:js),
      className: valid_as_daily_run? ? 'valid' : 'invalid'
    }
  end

  def manifest_slack_travel_times
    slack_info = []
    itineraries.where.not(time: nil).where.not(eta: nil)
      .includes(trip: :customer).references(trip: :customer)
      .pluck(:time, :eta, :leg_flag, :trip_id, "customers.first_name || '' || customers.last_name").each do |itin|
      time = (itin[0] - itin[0].beginning_of_day) / 3600.0
      eta = (itin[1] - itin[1].beginning_of_day) / 3600.0
      is_late = eta > time
      slack_time = ((eta - time) * 60)
      slack_info << {
        time_point: (is_late ? eta : time),
        slack_time: (slack_time > 0 ? slack_time.ceil : slack_time.floor),
        leg_flag: itin[2],
        trip_id: itin[3],
        customer: itin[4]
      }
    end

    slack_info.sort_by{|x| x[:time_point]}
  end

  def self.fake_cab_run
    Run.new name: 'Cab', id: Run::CAB_RUN_ID
  end

  def self.fake_standby_run
    Run.new name: 'Standby', id: Run::STANDBY_RUN_ID
  end

  def self.fake_unscheduled_run
    Run.new name: 'Unscheduled', id: Run::UNSCHEDULED_RUN_ID
  end

  def self.update_prior_run_complete_status!
    Run.prior_to(Date.today).where(provider: Provider.active.pluck(:id)).incomplete.each do |r|
      if r.completable?
        r.set_complete!
      end
    end
  end

  def completable?
    start_odometer.present? && end_odometer.present? && start_odometer < end_odometer &&
    vehicle_id.present?  && driver_id.present? &&
    (from_garage_address || vehicle.try(:garage_address)) &&
    (to_garage_address || vehicle.try(:garage_address)) &&
    trips.incomplete.empty?  &&
    check_provider_fields_required_for_run_completion 
  end

  # lists incomplete reason
  def incomplete_reason
    return [] if complete?

    reasons = []

    unless driver_id
      reasons << "Driver not assigned"
    end
    unless vehicle_id
      reasons << "Vehicle not assigned"
    end
    unless start_odometer
      reasons << "Missing beginning mileage"
    end
    unless end_odometer
      reasons << "Missing ending mileage"
    end

    (provider.fields_required_for_run_completion & Run::FIELDS_FOR_COMPLETION.map(&:to_s)).each do |extra_field|
      if extra_field == "paid" && self.send(extra_field).nil?
        reasons << "Paid field is not specified"
      elsif extra_field == "unpaid_driver_break_time" && self.send(extra_field).nil?
        reasons << "Driver Unpaid Break Time field is not specified"
      end
    end

    if trips.incomplete.any?
      reasons << "Has #{trips.incomplete.count} pending trip(s)"
    end

    unless (from_garage_address || vehicle.try(:garage_address))
      reasons << "Missing start location"
    end

    unless (to_garage_address || vehicle.try(:garage_address)) 
      reasons << "Missing end location"
    end

    if reasons.empty?
      reasons << "No missing data, please go to run details page to complete it"
    end

    reasons
  end

  def set_complete!(user = nil)
    if !self.from_garage_address
      self.from_garage_address = self.vehicle.try(:garage_address).try(:dup)
    end
    if !self.to_garage_address
      self.to_garage_address = self.vehicle.try(:garage_address).try(:dup)
    end
    self.complete = true
    self.uncomplete_reason = nil
    self.save(validate: false)
    RunDistanceCalculationWorker.perform_async(self.id)
    TrackerActionLog.complete_run(self, user)
  end

  def set_incomplete!(reason = nil, user = nil)
    self.complete = false
    self.uncomplete_reason = reason
    self.save(validate: false)
    self.run_distance.destroy if self.run_distance
    TrackerActionLog.uncomplete_run(self, user)
  end
  
  # Returns sum of actual run hours across a collection
  def self.total_actual_hours
    total_hours(actual: true)
  end

  # Returns sum of scheduled run hours across a collection
  def self.total_scheduled_hours
    total_hours(actual: false)
  end

  # Returns the total hours of a collection of runs
  def self.total_hours(opts={actual: true})
    query_str = opts[:actual] ? 'actual_end_time - actual_start_time' : 'scheduled_end_time - scheduled_start_time'
    sum("extract(epoch from (#{query_str}))") / 3600.0
  end

  def duration_in_hours
    actual_start_time && actual_end_time ? hours_operated : hours_scheduled
  end

  # Returns length in hours for an individual run. Use scheduled hours
  def hours_scheduled
    seconds = scheduled_end_time - scheduled_start_time
    seconds / 3600.0
  end

  # Returns length in hours for an individual run. Use scheduled hours
  def hours_operated
    if actual_start_time && actual_end_time
      seconds = actual_end_time - actual_start_time
      seconds / 3600.0
    end
  end

  # sum up number_of_passengers in each tracking type from completed trips
  def number_of_passengers_served(tracking_type)
    field_name = get_trip_tracking_field_name(tracking_type)
    trips.completed.sum(field_name)
  end

  # count one way trips in each tracking type
  def number_of_one_way_trips(tracking_type)
    field_name = get_trip_tracking_field_name(tracking_type)
    trips.where("#{field_name} > 0").count
  end
  
  # checks if a run would be valid if it weren't child run
  def valid_as_daily_run?
    r = self.clone
    r.repeating_run = nil
    r.valid?
  end

  def vehicle_inspections_as_json
    run_inspection_data = self.run_vehicle_inspections.pluck(:vehicle_inspection_id, :checked).to_h
    inspection_as_json = []
    VehicleInspection.by_provider(self.provider).pluck(:id, :description).each do |v|
      inspection_as_json << {
        id: v[0],
        description: v[1],
        checked: run_inspection_data[v[0]]
      }
    end

    inspection_as_json
  end

  private

  def fix_dates
    d = self.date
    unless d.nil?
      if !scheduled_start_time.nil? && d != scheduled_start_time.to_date
        s = scheduled_start_time
        self.scheduled_start_time = Time.zone.local(d.year, d.month, d.day, s.hour, s.min, 0)
        scheduled_start_time_will_change!
      end
      if !scheduled_end_time.nil? && d != scheduled_end_time.to_date
        s = scheduled_end_time
        self.scheduled_end_time = Time.zone.local(d.year, d.month, d.day, s.hour, s.min, 0)
        scheduled_end_time_will_change!
      end
      if !actual_start_time.nil? && d != actual_start_time.to_date
        a = actual_start_time
        self.actual_start_time = Time.zone.local(d.year, d.month, d.day, a.hour, a.min, 0)
        actual_start_time_will_change!
      end
      if !actual_end_time.nil? && d != actual_end_time.to_date
        a = actual_end_time
        self.actual_end_time = Time.zone.local(d.year, d.month, d.day, a.hour, a.min, 0)
        actual_end_time_will_change!
      end
    end
    true
  end
  
  
  ### NAME UNIQUENESS ###
  # Is the name unique by date and provider among daily and repeating runs?
  def name_uniqueness
    return true if date.nil? || name.nil? || provider.nil?
    daily_name_uniqueness
    repeating_name_uniqueness
  end
  
  # determines if any daily runs overlap with this run and have the same name and provider
  def daily_name_uniqueness
    if provider.runs      # same provider
        .for_date(date)     # same date
        .where("lower(name) = ?", name.try(:to_s).downcase)  # same name
        .other_than(self)   # not the same run
        .present?
      errors.add(:name,  "should be unique by day and by provider among daily runs")
    end
  end
  
  # determines if any repeating runs overlap with this run and have the same name and provider
  # skip this validation if the date is within the advance day scheduling window for the provider
  def repeating_name_uniqueness
    return true if provider.scheduler_window_covers?(date)
    if provider.repeating_runs    # same provider
        .where("lower(name) = ?", name.try(:to_s).downcase)          # same name
        .not_the_parent_of(self)    # not the parent repeating run
        .schedule_occurs_on(date)   # repeating run schedule occurs on this run's date
        .present?
      errors.add(:name,  "should be unique by day and by provider among repeating runs")
    end
  end
  ###
  

  ### DRIVER AVAILABILITY ###
  # Validates that the driver is not assigned to any overlapping daily or repeating runs
  def driver_availability
    return true if date.nil? || driver.nil?
    daily_driver_availability
    repeating_driver_availability
  end
  
  def daily_driver_availability
    if Run.other_overlapped_runs(self).pluck(:driver_id).include?(self.driver_id)
      errors.add(:driver_id, TranslationEngine.translate_text(:assigned_to_other_overlapping_run))
    end
  end
  
  def repeating_driver_availability
    return true if provider.scheduler_window_covers?(date)
    if RepeatingRun.where(driver: driver).active   # same driver
        .not_the_parent_of(self)            # not the parent repeating run
        .overlaps_with_run(self)            # repeating run schedule occurs on this run's date and time
        .present?
      errors.add(:driver_id, TranslationEngine.translate_text(:assigned_to_overlapping_repeating_run))
    end
  end
  ###


  ### VEHICLE AVAILABILITY ###
  # Validates that the vehicle is not assigned to any overlapping daily or repeating runs
  def vehicle_availability
    return true if date.nil? || vehicle.nil?
    daily_vehicle_availability
    repeating_vehicle_availability
  end
  
  def daily_vehicle_availability
    if Run.other_overlapped_runs(self).pluck(:vehicle_id).include?(self.vehicle.id)
      errors.add(:vehicle_id, TranslationEngine.translate_text(:assigned_to_other_overlapping_run))
    end
  end
  
  def repeating_vehicle_availability
    return true if provider.scheduler_window_covers?(date)
    if RepeatingRun.where(vehicle: vehicle).active   # same vehicle
        .not_the_parent_of(self)              # not the parent repeating run
        .overlaps_with_run(self)              # repeating run schedule occurs on this run's date and time
        .present?
      errors.add(:vehicle_id, TranslationEngine.translate_text(:assigned_to_overlapping_repeating_run))
    end
  end
  ###
  
  def check_provider_fields_required_for_run_completion
    provider.present? && provider.fields_required_for_run_completion.select{ |attr| self[attr].blank? if FIELDS_FOR_COMPLETION.include?(attr.try(:to_sym)) }.empty?
  end

  def within_advance_day_scheduling
    advance_day_scheduling = provider.try(:get_advance_day_scheduling)
    if date && advance_day_scheduling.present? && (date - Date.current).to_i > advance_day_scheduling
      errors.add(:date, TranslationEngine.translate_text(:beyond_advance_day_scheduling) % {advance_day_scheduling: advance_day_scheduling})
    end
  end

  def get_trip_tracking_field_name(tracking_type)
    if ['senior', 'disabled', 'low_income'].include?(tracking_type.to_s)
      "number_of_#{tracking_type}_passengers_served"
    end
  end
  
  # Returns true if run was generated by a parent repeating run
  def child_run?
    repeating_run.present?
  end

  def check_vehicle_change
    if self.changes.include?(:vehicle_id)
      self.from_garage_address = self.vehicle.try(:garage_address).try(:dup) 
      self.to_garage_address = self.vehicle.try(:garage_address).try(:dup) 
    end

    true
  end

  def check_manifest_change
    if self.changes.include?(:date)
      @unschedule_trips = true
    else
      if (self.changes.keys & ["scheduled_start_time", "scheduled_end_time", "from_garage_address_id", "to_garage_address_id"]).any?
        @clear_manifest_times = true
      end
    end

    if @unschedule_trips || @clear_manifest_times || self.changes.include?('manifest_order')
      self.manifest_changed = true 
    end

    true
  end  

  def apply_manifest_changes
    if @unschedule_trips
      self.unschedule!(false)
    elsif @clear_manifest_times
      self.itineraries.clear_times!
      self.itineraries.run_begin.update_all(time: self.scheduled_start_time, address_id: self.from_garage_address.try(:id) || self.vehicle.try(:garage_address).try(:id))
      self.itineraries.run_end.update_all(time: self.scheduled_end_time, address_id: self.to_garage_address.try(:id) || self.vehicle.try(:garage_address).try(:id))
    end

    true
  end

  def add_init_run_itineraries
    Itinerary.transaction do
      build_begin_run_itinerary.save
      build_end_run_itinerary.save
    end
  end
  
end
