class Vehicle < ActiveRecord::Base
  include RequiredFieldValidatorModule 

  acts_as_paranoid # soft delete
  
  OWNERSHIPS = [:agency, :volunteer].freeze

  has_paper_trail

  belongs_to :default_driver, :class_name => "Driver"
  belongs_to :provider
  
  has_one :device_pool_driver, :dependent => :destroy
  has_one :device_pool, :through => :device_pool_driver
  
  has_many :documents, as: :documentable, dependent: :destroy, inverse_of: :documentable
  has_many :runs, inverse_of: :vehicle # TODO add :dependent rule
  has_many :trips, through: :runs
  has_many :vehicle_maintenance_events, dependent: :destroy, inverse_of: :vehicle
  has_many :vehicle_warranties, dependent: :destroy, inverse_of: :vehicle

  # We must specify :delete_all in order to avoid the before_destroy hook. See
  # the RecurringComplianceEvent concern for more details. 
  # TODO Look into using `#mark_for_destruction` and `#marked_for_destruction?`
  has_many :vehicle_maintenance_compliances, dependent: :delete_all, inverse_of: :vehicle

  validates :provider, presence: true
  validates :default_driver, presence: true
  validates :name, presence: true
  validates :vin, length: {is: 17, allow_nil: true, allow_blank: true},
    format: {with: /\A[^ioq]*\z/i, allow_nil: true}
  validates_date :registration_expiration_date, allow_blank: true
  validates :seating_capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :ownership, inclusion: { in: OWNERSHIPS.map(&:to_s), allow_blank: true }

  scope :active,        -> { where(active: true) }
  scope :for_provider,  -> (provider_id) { where(provider_id: provider_id) }
  scope :reportable,    -> { where(reportable: true) }
  scope :default_order, -> { order(:name) }

  def self.unassigned(provider)
    for_provider(provider).reject { |vehicle| vehicle.device_pool.present? }
  end

  def last_odometer_reading
    runs.where().not(end_odometer: nil).last.try(:end_odometer).to_i
  end

  def compliant?(as_of: Date.current)
    vehicle_maintenance_compliances.overdue(as_of: as_of).empty?
  end  

  def expired?(as_of: Date.current)
    vehicle_warranties.expired(as_of: as_of).any?
  end
  
  def open_seating_capacity(start_time, end_time, ignore: nil)
    seating_capacity - (trips.incomplete.during(start_time, end_time) - Array(ignore)).collect(&:trip_size).flatten.compact.sum
  end
end
