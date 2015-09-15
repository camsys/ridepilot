require 'active_support/concern'

module RecurringRideCoordinator
  extend ActiveSupport::Concern

  DAYS_OF_WEEK = %w{monday tuesday wednesday thursday friday saturday sunday}

  included do
    attr_accessor :via_recurring_ride_coordinator_scheduler

    before_create :create_recurring_ride_coordinator
    before_update :update_recurring_ride_coordinator
    after_save    :instantiate_recurring_ride_coordinators

    DAYS_OF_WEEK.each do |day|
      define_method "repeats_#{day}s=" do |value|
        instance_variable_set "@repeats_#{day}s", (value == "1" || value == true)
      end

      define_method "repeats_#{day}s" do
        if instance_variable_get("@repeats_#{day}s").nil?
          if send(self.class.occurrence_scheduler_association).present?
            instance_variable_set "@repeats_#{day}s", send(self.class.occurrence_scheduler_association).schedule_attributes.send(day) == 1
          else
            instance_variable_set "@repeats_#{day}s", false 
          end
        else
          instance_variable_get("@repeats_#{day}s")
        end
      end
    end
  end
  
  module ClassMethods
    attr_reader :occurrence_scheduler_association
    attr_reader :occurrence_scheduler_association_id
    attr_reader :occurrence_scheduler_class
    attr_reader :occurrence_attribute_block
    attr_reader :occurrence_destroy_future_recurring_ride_coordinators_block
    attr_reader :occurrence_unlink_past_recurring_ride_coordinators_block

    private

    # Setup method for including class. Accepts 1 unnamed argument and 3 - 4
    # named arguments:
    #   Unnamed:
    #     association: A symbol representing the association for the scheduler
    #   Named:
    #     with_attributes: A proc that accepts one argument, the coordinator 
    #       itself (i.e. a trip or run), to be called by 
    #       #recurring_ride_coordinator_attributes
    #     destroy_future_occurrences_with: A proc that accepts one argument, 
    #       the coordinator itself (i.e. a trip or run), to be called by
    #       #destroy_future_recurring_ride_coordinators
    #     unlink_past_occurrences_with: A proc that accepts one argument, the 
    #       coordinator itself (i.e. a trip or run), to be called by 
    #       #unlink_past_recurring_ride_coordinators
    #     class_name: (optional) A string representing the class name of the 
    #       associated scheduler if it can't be inferred from the association 
    #       argument
    def schedules_occurrences_with(association, with_attributes:, destroy_future_occurrences_with:, unlink_past_occurrences_with:, class_name: nil)
      @occurrence_scheduler_association = association
      @occurrence_scheduler_association_id = "#{association}_id"
      @occurrence_attribute_block = with_attributes
      @occurrence_destroy_future_recurring_ride_coordinators_block = destroy_future_occurrences_with
      @occurrence_unlink_past_recurring_ride_coordinators_block = unlink_past_occurrences_with
      @occurrence_scheduler_class = if class_name.present?
        if class_name.is_a? Class
          class_name
        else
          class_name.to_s.camelize.constantize
        end
      else
        association.to_s.singularize.camelize.constantize
      end

      belongs_to @occurrence_scheduler_association

      scope :repeating_based_on, -> (scheduler) { where(@occurrence_scheduler_association_id => scheduler.id) }
    end
  end
  
  def repetition_driver_id=(value)
    @repetition_driver_id = (value.blank? ? nil : value.to_i)
  end

  def repetition_driver_id
    if @repetition_driver_id.nil?
      @repetition_driver_id = send(self.class.occurrence_scheduler_association).try :driver_id
    else
      @repetition_driver_id
    end
  end

  def repetition_vehicle_id=(value)
    @repetition_vehicle_id = (value.blank? ? nil : value.to_i)
  end

  def repetition_vehicle_id
    if @repetition_vehicle_id.nil?
      @repetition_vehicle_id = send(self.class.occurrence_scheduler_association).try :vehicle_id
    else
      @repetition_vehicle_id
    end
  end

  def repetition_interval=(value)
    @repetition_interval = value.to_i
  end

  def repetition_interval
    if @repetition_interval.nil?
      if send(self.class.occurrence_scheduler_association).present?
        @repetition_interval = send(self.class.occurrence_scheduler_association).schedule_attributes.interval 
      else
        1
      end
    else
      @repetition_interval
    end
  end

  def is_recurring_ride_coordinator?
    (repetition_interval || 0) > 0 &&
    (
      repeats_mondays    ||
      repeats_tuesdays   ||
      repeats_wednesdays ||
      repeats_thursdays  ||
      repeats_fridays    ||
      repeats_saturdays  ||
      repeats_sundays
    )
  end
  
  private
  
  def create_recurring_ride_coordinator
    if is_recurring_ride_coordinator? && !via_recurring_ride_coordinator_scheduler
      self.send("#{self.class.occurrence_scheduler_association}=", self.class.occurrence_scheduler_class.create!(recurring_ride_coordinator_attributes))
    end
  end

  def update_recurring_ride_coordinator
    if is_recurring_ride_coordinator? 
      # This is a repeating ride coordinator, so we need to edit both the 
      # scheduler and the occurrences for today
      if send(self.class.occurrence_scheduler_association).blank?
        create_recurring_ride_coordinator
      else
        send(self.class.occurrence_scheduler_association).attributes = recurring_ride_coordinator_attributes
        if send(self.class.occurrence_scheduler_association).changed?
          send(self.class.occurrence_scheduler_association).save!
          destroy_future_recurring_ride_coordinators
        end
      end
    elsif !is_recurring_ride_coordinator? && send(self.class.occurrence_scheduler_association).present?
      destroy_future_recurring_ride_coordinators
      unlink_past_recurring_ride_coordinators
      rt = send(self.class.occurrence_scheduler_association)
      self.send("#{self.class.occurrence_scheduler_association_id}=", nil)
      rt.destroy
    end
  end

  def instantiate_recurring_ride_coordinators
    send(self.class.occurrence_scheduler_association).instantiate! if !send(self.class.occurrence_scheduler_association_id).nil? && !via_recurring_ride_coordinator_scheduler
  end

  def destroy_future_recurring_ride_coordinators
    self.class.occurrence_destroy_future_recurring_ride_coordinators_block.call self
  end

  def unlink_past_recurring_ride_coordinators
    self.class.occurrence_unlink_past_recurring_ride_coordinators_block.call self
  end

  def recurring_ride_coordinator_attributes
    self.class.occurrence_attribute_block.call self
  end  
end
