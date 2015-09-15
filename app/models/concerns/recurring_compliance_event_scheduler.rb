require 'active_support/concern'

module RecurringComplianceEventScheduler
  extend ActiveSupport::Concern

  RECURRENCE_SCHEDULES = [:days, :weeks, :months, :years].freeze
  FUTURE_START_RULES = [:immediately, :on_schedule, :time_span].freeze

  included do
    belongs_to :provider
  
    after_update :update_children

    scope :default_order, -> { order("start_date DESC") }
  
    validates :provider, presence: true
    validates :event_name, presence: true
    validates :recurrence_schedule, inclusion: { in: RECURRENCE_SCHEDULES.map(&:to_s), allow_blank: true }
    validates :recurrence_frequency, numericality: { only_integer: true, greater_than: 0, allow_blank: true }
    validates :future_start_rule, inclusion: { in: FUTURE_START_RULES.map(&:to_s) }
    validates :future_start_schedule, inclusion: { in: RECURRENCE_SCHEDULES.map(&:to_s), if: :future_start_rule_is_time_span? }
    validates :future_start_frequency, numericality: { only_integer: true, greater_than: 0, if: :future_start_rule_is_time_span? }
    validates_date :start_date, on_or_after: -> { Date.current }, allow_blank: true
    validates :compliance_based_scheduling, inclusion: { in: [true, false] }
    validate :limit_updates_on_recurrences_with_children, on: :update
      
    def destroy_with_incomplete_children!
      self.class.transaction do
        child_ids = self.send(self.class.occurrence_association).incomplete.pluck(:id)
        self.destroy
        self.class.occurrence_class.destroy_all(id: child_ids)
      end
    end

    def occurrences_for_owner(owner)
      send(self.class.occurrence_association).send(self.class.occurrence_association_scope_for_owner, owner)
    end
    
    private
    
    def future_start_rule_is_time_span?
      future_start_rule.present? && future_start_rule.to_sym == :time_span
    end

    # Only allow updating the event_name and event_notes fields if the record is
    # associated with any compliance occurrences
    def limit_updates_on_recurrences_with_children
      if self.send(self.class.occurrence_association).any?
        changed_attributes.except(:recurrence_notes, :event_name, :event_notes).keys.each do |key|
          errors.add(key, "cannot be modified once events have been generated")
        end
      end
    end

    def update_children
      self.send(self.class.occurrence_association).update_all event: event_name, notes: event_notes
    end
  end
  
  module ClassMethods 
    attr_reader :occurrence_association
    attr_reader :occurrence_class
    attr_reader :occurrence_owner_association
    attr_reader :occurrence_association_scope_for_owner
    attr_reader :recurrence_attribute
    attr_reader :occurrence_generator_block
    attr_reader :occurrence_attribute_block

    def generate!(*opts)
      set_generate_options(opts.extract_options!)
      
      transaction do
        find_each do |recurrence|
          # Ensures that the next steps all work off the same collection
          collection = recurrence.send(@occurrence_owner_association)
          
          if @occurrence_generator_block.is_a? Proc
            @occurrence_generator_block.call recurrence, collection
          else
            default_generator recurrence, collection
          end
        end
      end
    end

    def occurrence_dates_on_schedule_in_range(recurrence, first_date: nil, range_start_date: nil, range_end_date: nil)
      first_date ||= recurrence.start_date
      range_start_date ||= Date.current
      range_end_date ||= (range_start_date + default_date_range_length - 1.day)
      next_date = first_date
    
      occurrences = []
      iterator = 0
      loop do
        break if next_date > range_end_date
        occurrences << next_date if next_date >= range_start_date
        next_date = first_date + (recurrence.recurrence_frequency * (iterator += 1)).send(recurrence.recurrence_schedule)
      end
      occurrences
    end
  
    # Public for testability purposes
    def next_occurrence_date_from_previous_date_in_range(recurrence, previous_date, range_end_date: nil)
      range_end_date ||= (Date.current + default_date_range_length - 1.day)
      next_date = previous_date + recurrence.recurrence_frequency.send(recurrence.recurrence_schedule)
    
      if next_date > range_end_date
        nil
      else
        next_date
      end
    end

    # Public for testability purposes
    def adjusted_start_date(recurrence, as_of: nil)
      as_of ||= Date.current

      if recurrence.start_date >= as_of
        recurrence.start_date
      else
        case recurrence.future_start_rule.to_sym
        when :immediately
          as_of
        when :on_schedule
          occurrence_dates_on_schedule_in_range(recurrence, range_start_date: as_of, range_end_date: (as_of + recurrence.recurrence_frequency.send(recurrence.recurrence_schedule))).first
        when :time_span
          as_of + recurrence.future_start_frequency.send(recurrence.future_start_schedule)
        end
      end
    end
    
    private

    # Setup method for including class
    def creates_occurrences_for(association, on:, class_name: nil, for_scope: nil)
      @occurrence_association = association
      @occurrence_class = if class_name.present?
        if class_name.is_a? Class
          class_name
        else
          class_name.to_s.camelize.constantize
        end
      else
        association.to_s.singularize.camelize.constantize
      end
      @occurrence_owner_association = on
      @occurrence_association_scope_for_owner = if for_scope.present?
        for_scope
      else
        "for_#{@occurrence_owner_association.to_s.singularize}".to_sym
      end
      @recurrence_attribute = name.underscore.to_sym

      # Setup some dynamic associations
      has_many @occurrence_owner_association, through: :provider
      has_many @occurrence_association, :dependent => :nullify, inverse_of: @recurrence_attribute
    end
    
    # Accepts a block. If present, it will be called instead of the
    # default_generate method. This block should accept two arguments: the 
    # recurrence instance, and a collection of owner objects.
    def generates_occurrences_with
      @occurrence_generator_block = Proc.new
    end
    
    # Accepts a block. If present, it will be called instead of the
    # default_occurrence_attributes method. This block should accept a minimum 
    # of two arguments: the owner, and the recurrence, plus any necessary 
    # options such as the occurrence_date
    def make_occurence_with_attributes
      @occurrence_attribute_block = Proc.new
    end
    
    def set_generate_options(opts = {})
      opts.each do |k, v|
        instance_variable_set("@default_#{k}", v)
      end
    end
    
    def default_generator(recurrence, collection)
      if recurrence.compliance_based_scheduling?
        schedule_compliance_based_occurrences! recurrence, collection
      else
        schedule_frequency_based_occurrences! recurrence, collection
      end
    end
    
    def schedule_compliance_based_occurrences!(recurrence, collection)
      collection.find_each do |record|
        previous_occurrences = recurrence.occurrences_for_owner(record)

        if previous_occurrences.any?
          if previous_occurrences.last.complete?
            # Schedule it based on whenever this one was complete
            next_occurence_date = next_occurrence_date_from_previous_date_in_range recurrence, previous_occurrences.last.compliance_date
          else
            # Nothing to schedule as the last one is still incomplete
            # noop
          end
        else
          # No previous one, schedule based on the adjusted_start_date
          next_occurence_date = adjusted_start_date(recurrence)
        end

        make_occurrence(record, recurrence, occurrence_date: next_occurence_date) if next_occurence_date.present?
      end
    end
  
    def schedule_frequency_based_occurrences!(recurrence, collection)
      collection.find_each do |record|
        previous_occurrences = recurrence.occurrences_for_owner(record)
        next_occurence_dates = []

        if previous_occurrences.any?
          # Find missing occurrence dates in range
          next_occurence_dates = occurrence_dates_on_schedule_in_range(recurrence) - previous_occurrences.pluck(:due_date)
        else
          # Find missing occurrence dates based on the adjusted_start_date
          next_occurence_dates = occurrence_dates_on_schedule_in_range recurrence, first_date: adjusted_start_date(recurrence)
        end

        next_occurence_dates.each do |occurrence_date|
          make_occurrence record, recurrence, occurrence_date: occurrence_date
        end
      end
    end
    
    def default_occurrence_attributes(owner, recurrence, occurrence_date)
      {
        event: recurrence.event_name,
        notes: recurrence.event_notes,
        due_date: occurrence_date,
        @recurrence_attribute => recurrence
      }
    end
  
    def make_occurrence(owner, recurrence, *opts)
      attributes = if @occurrence_attribute_block.is_a? Proc
        @occurrence_attribute_block.call owner, recurrence, opts.extract_options!
      else
        default_occurrence_attributes owner, recurrence, opts.extract_options![:occurrence_date]
      end
      
      owner.send(@occurrence_association).create! attributes
    end

    def default_date_range_length
      @default_date_range_length || 6.months
    end
  end
end
