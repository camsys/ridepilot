# As is documented verily on the Interwebs, validates_uniqueness_of with :scope 
# doesn't work properly in conjunction with accepts_nested_attributes_for, as 
# the validation is only run on persisted records, not the new records being
# inserted. This gets around the problem.
# H/T https://github.com/rails/rails/issues/1572#issuecomment-17386774
# WARNING: memory usage is correlated to the size of the collection!

module ActiveRecord
  class Base
    # Validate that *new* objects in the +collection+ are unique
    # when compared against all their non-blank +attrs+. If not
    # add +message+ to the base errors.
    def validate_uniqueness_of_in_memory(collection, attrs, message)
      hashes = collection.inject({}) do |hash, record|
        key = attrs.map {|a| record.send(a).to_s }.join
        if key.blank? || record.marked_for_destruction? || record.persisted?
          key = record.object_id
        end
        hash[key] = record unless hash[key]
        hash
      end
      if collection.length > hashes.length
        self.errors.add(:base, message)
      end
    end
  end
end