class RecurringVehicleMaintenanceCompliance < ActiveRecord::Base
  include RecurringComplianceEventScheduler
  creates_occurrences_for :vehicle_maintenance_compliances, on: :vehicles
  generates_occurrences_with do |recurrence, collection|
    custom_vehicle_maintenance_compliance_generator recurrence, collection
  end
  make_occurence_with_attributes do |owner, recurrence, *opts|
    options = opts.extract_options!
    default_occurrence_attributes(owner, recurrence, options[:occurrence_date]).merge({
      due_type: options[:occurrence_type] || 'date',
      due_mileage: options[:occurrence_mileage]
    })
  end

  validates :recurrence_type, inclusion: { in: VehicleMaintenanceCompliance::DUE_TYPES.map(&:to_s) }
  validates :recurrence_schedule, presence: { if: :recurrence_schedule_required? }
  validates :recurrence_frequency, presence: { if: :recurrence_schedule_required? }
  validates :recurrence_mileage, numericality: { only_integer: true, greater_than: 0, allow_blank: true }
  validates :recurrence_mileage, presence: { if: :recurrence_mileage_required? }
  validates :start_date, presence: { if: :recurrence_schedule_required? }
  validate  :time_span_future_start_rule_not_allowed, unless: :recurrence_schedule_required?

  class << self
    def occurrence_mileages_on_schedule_in_range(recurrence, first_mileage: 0, range_start_mileage: 0, range_end_mileage: nil)
      range_end_mileage ||= (range_start_mileage + default_mileage_range_length)
      next_mileage = first_mileage

      occurrences = []
      iterator = 0
      loop do
        break if next_mileage > range_end_mileage
        occurrences << next_mileage if next_mileage >= range_start_mileage
        next_mileage = next_mileage + recurrence.recurrence_mileage
      end
      occurrences
    end

    def next_occurrence_mileage_from_previous_mileage_in_range(recurrence, previous_mileage, range_end_mileage: nil)
      range_end_mileage ||= default_mileage_range_length
      next_mileage = previous_mileage + recurrence.recurrence_mileage

      if next_mileage > range_end_mileage
        nil
      else
        next_mileage
      end
    end

    # Unlike date based schedules, mileage based schedules should always be
    # on schedule (i.e. multiples of the recurrence_mileage)
    def adjusted_start_mileage(recurrence, as_of: 0)
      if recurrence.recurrence_mileage >= as_of
        recurrence.recurrence_mileage
      else
        occurrence_mileages_on_schedule_in_range(recurrence, range_start_mileage: as_of, range_end_mileage: (as_of + recurrence.recurrence_mileage)).first
      end
    end
    
    private
    
    def next_occurence_mileages_for_vehicle(recurrence, vehicle)
      # Gather mileage occurrences based on the adjusted_start_mileage,
      # starting with the vehicle's current last_odometer_reading, and
      # out as far as `default_mileage_range_length` miles
      as_of = vehicle.last_odometer_reading
      first_mileage = adjusted_start_mileage(recurrence, as_of: as_of)
      range_end_mileage = as_of + default_mileage_range_length
      occurrence_mileages_on_schedule_in_range recurrence, first_mileage: first_mileage, range_end_mileage: range_end_mileage
    end

    def schedule_vehicle_maintenance_compliance_based_mileage_occurrences!(recurrence, vehicle)
      previous_occurrences = recurrence.occurrences_for_owner(vehicle)

      if previous_occurrences.any?
        if previous_occurrences.last.complete?
          # Schedule it based on whenever this one was complete
          next_occurence_mileage = next_occurrence_mileage_from_previous_mileage_in_range recurrence, previous_occurrences.last.compliance_mileage
        else
          # Nothing to schedule as the last one is still incomplete
          # noop
        end
      else
        # No previous one, schedule based on the adjusted_start_mileage
        next_occurence_mileage = adjusted_start_mileage(recurrence, as_of: vehicle.last_odometer_reading)
      end

      make_occurrence(vehicle, recurrence, occurrence_type: "mileage", occurrence_mileage: next_occurence_mileage) if next_occurence_mileage.present?
    end
    
    def schedule_vehicle_maintenance_frequency_based_mileage_occurrences!(recurrence, vehicle)
      previous_occurrences = recurrence.occurrences_for_owner(vehicle)
      next_occurence_mileages = next_occurence_mileages_for_vehicle(recurrence, vehicle)
      next_occurence_mileages -= previous_occurrences.pluck(:due_mileage) if previous_occurrences.any?
      
      next_occurence_mileages.each do |occurrence_mileage|
        make_occurrence vehicle, recurrence, occurrence_type: "mileage", occurrence_mileage: occurrence_mileage
      end
    end

    def schedule_vehicle_maintenance_compliance_based_both_occurrences!(recurrence, vehicle)
      previous_occurrences = recurrence.occurrences_for_owner(vehicle)

      if previous_occurrences.any?
        if previous_occurrences.last.complete?
          # Schedule it based on whenever this one was complete
          next_occurence_date = next_occurrence_date_from_previous_date_in_range recurrence, previous_occurrences.last.compliance_date
          next_occurence_mileage = next_occurrence_mileage_from_previous_mileage_in_range recurrence, previous_occurrences.last.compliance_mileage
        else
          # Nothing to schedule as the last one is still incomplete
          # noop
        end
      else
        # No previous one, schedule based on the adjusted_start_date
        next_occurence_date = adjusted_start_date(recurrence)
        next_occurence_mileage = adjusted_start_mileage(recurrence, as_of: vehicle.last_odometer_reading)
      end

      make_occurrence(vehicle, recurrence, occurrence_type: "both", occurrence_date: next_occurence_date, occurrence_mileage: next_occurence_mileage) if next_occurence_mileage.present?
    end

    def schedule_vehicle_maintenance_frequency_based_both_occurrences!(recurrence, vehicle)
      # Get a list of date occurrences, and a list of mileage occurrences, 
      # and zip them together, ignoring any orphans at the end

      previous_occurrences = recurrence.occurrences_for_owner(vehicle)
      next_occurences = []

      if previous_occurrences.any?
        next_occurence_dates = occurrence_dates_on_schedule_in_range(recurrence) - previous_occurrences.pluck(:due_date)
        next_occurence_mileages = next_occurence_mileages_for_vehicle(recurrence, vehicle) - previous_occurrences.pluck(:due_mileage)
        next_occurences = zip_occurence_arrays next_occurence_dates, next_occurence_mileages
      else
        # Find missing occurrence dates based on the adjusted_start_date
        next_occurence_dates = occurrence_dates_on_schedule_in_range recurrence, first_date: adjusted_start_date(recurrence)
        next_occurence_mileages = next_occurence_mileages_for_vehicle(recurrence, vehicle)
        next_occurences = zip_occurence_arrays next_occurence_dates, next_occurence_mileages
      end

      next_occurences.each do |occurrence_date, occurrence_mileage|
        make_occurrence vehicle, recurrence, occurrence_type: "both", occurrence_date: occurrence_date, occurrence_mileage: occurrence_mileage
      end
    end

    def custom_vehicle_maintenance_compliance_generator(recurrence, collection)
      if recurrence.recurrence_type.to_sym == :date
        default_generator recurrence, collection
      else
        scheduling_rule = recurrence.compliance_based_scheduling? ? "compliance" : "frequency"
        scheduling_type = recurrence.recurrence_type
        
        collection.find_each do |vehicle|
          send("schedule_vehicle_maintenance_#{scheduling_rule}_based_#{scheduling_type}_occurrences!", recurrence, vehicle)
        end
      end
    end

    def default_mileage_range_length
      @default_mileage_range_length || 6000
    end
    
    def zip_occurence_arrays(arr1, arr2)
      arr1.zip(arr2).reject { |arr| arr != arr.compact }
    end
    
  end

  private

  def time_span_future_start_rule_not_allowed
    if recurrence_type.try(:to_sym) == :mileage and future_start_rule.try(:to_sym) == :time_span
      errors.add(:future_start_rule, "cannot be time_span when the recurrence type is 'mileage'")
    end
  end

  def recurrence_schedule_required?
    [:both, :date].include? recurrence_type.try(:to_sym)
  end

  def recurrence_mileage_required?
    [:both, :mileage].include? recurrence_type.try(:to_sym)
  end
end
