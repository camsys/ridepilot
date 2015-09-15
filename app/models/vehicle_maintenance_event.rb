class VehicleMaintenanceEvent < ActiveRecord::Base
  include DocumentAssociable

  has_paper_trail

  belongs_to :vehicle, inverse_of: :vehicle_maintenance_events
  
  validates :vehicle, presence: true
  validates :services_performed, presence: true
  validates_date :service_date

  scope :default_order, -> { order("service_date DESC") }
end
