class VehicleWarranty < ActiveRecord::Base
  include DocumentAssociable

  belongs_to :vehicle, inverse_of: :vehicle_warranties
  
  validates_presence_of :vehicle, :description
  validates_date :expiration_date
  
  scope :expired, -> (as_of: Date.current) { where("expiration_date < ?", as_of) }
  scope :expiring_soon, -> (as_of: Date.current, through: nil) { where(expiration_date: as_of..(through || as_of + 6.days)) }
  scope :default_order, -> { order(expiration_date: :desc) }

  def expired?
    expiration_date < Date.current
  end
end
