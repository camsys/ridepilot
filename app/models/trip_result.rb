class TripResult < ActiveRecord::Base
  acts_as_paranoid # soft delete
  
  validates_presence_of :name, :code
end
