class TripResult < ActiveRecord::Base
  acts_as_paranoid
  
  validates_presence_of :name, :code
end
