require 'active_support/concern'

# Use with `include DocumentAssociable`
# Assumes that the associable will be either a DriverHistory, DriverCompliance,
# or (soon) some sort of vehicle event model, and thus that the owner will be
# either a Driver or a Vehicle. 
module DocumentAssociable
  extend ActiveSupport::Concern

  included do
    has_many :document_associations, as: :associable, dependent: :destroy, inverse_of: :associable
    accepts_nested_attributes_for :document_associations, allow_destroy: true, reject_if: proc { |attributes| attributes['document_id'].blank? }
    validate  :uniqueness_of_document_associations_in_memory
    
    private

    # As is documented verily on the Interwebs, validates_uniqueness_of with 
    # :scope doesn't always work properly with accepts_nested_attributes_for, 
    # specifically when adding new records, as the validation is only run on 
    # persisted records, not the new records being inserted. This gets around 
    # the problem.
    def uniqueness_of_document_associations_in_memory
      validate_uniqueness_of_in_memory(
        document_associations,
        [:document_id, :associable_type, :associable_id],
        'Document associations documents can\'t be associated to the same record more than once.'
      )
    end
  end
  
  # This is mainly available for testing
  def associable_owner
    # This should be either a driver or a vehicle. If others are required, make
    # sure to account for them below, or make the including class define this 
    # method
     if self.respond_to? :driver
       driver
     elsif self.respond_to? :vehicle
       vehicle
     else
       raise "Unsupported associable object: can't call `associable_owner`"
     end
  end
  
  # This is mainly available for testing
  def associable_owner=(owner)
    # This should be either a driver or a vehicle. If others are required, make
    # sure to account for them below, or make the including class define this 
    # method
     if self.respond_to? :driver
       self.driver = owner
     elsif self.respond_to? :vehicle
       self.vehicle = owner
     else
       raise "Unsupported associable object: can't call `associable_owner=`"
     end
  end
  
  def associable_name
    # The associable will probably have a field named `event` that we can use.
    # If it gets more complex as other associable models are created, we could
    # make the including class define this method or add branching logic and 
    # raise an error if it's not detectable.
    if self.respond_to? :event
      event
    else
      raise "Unsupported associable object: can't call `name`"
    end
  end

  def associable_date
    # The associable will probably have a field named `event_date` or 
    # `due_date` that we can use. If it gets more complex as other associable 
    # models are created, we could make the including class define this method 
    # or add branching logic and raise an error if it's not detectable.
    if self.respond_to? :event_date
      event_date
    elsif self.respond_to? :due_date
      due_date
    else
      raise "Unsupported associable object: can't call `date`"
    end
  end
end


