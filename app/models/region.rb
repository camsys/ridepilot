class Region < ActiveRecord::Base
  acts_as_paranoid # soft delete
end
