require 'active_support/concern'

module RecurringComplianceEvent
  extend ActiveSupport::Concern

  included do
    before_destroy :prevent_destroy_on_recurring_events
    validate :limit_updates_on_recurring_events, on: :update
  end
  
  module ClassMethods 
    def editable_occurrence_attributes
      raise "Must be defined by including class"
    end
  end

  def is_recurring?
    raise "Must be defined by including class"
  end

  private
  
  # Prevent destruction when there is an associated RecurringDriverCompliance.
  # Note that because of this we specify :delete_all in the Driver model for
  # the :driver_compliances association, so callbacks on this model are not
  # fired during a cascade delete from a driver!
  def prevent_destroy_on_recurring_events
    errors.add(:base, "Automatically generated events cannot be deleted") if is_recurring?
    errors.empty?
  end

  # Only allow updating the compliance_date field if the record is associated 
  # with a RecurringDriverCompliance record
  def limit_updates_on_recurring_events
    if is_recurring?
      changed_attributes.except(*self.class.editable_occurrence_attributes).keys.each do |key|
        errors.add(key, "cannot be modified on an automatically generated event")
      end
    end
  end
end
