class Vehicle < ApplicationRecord
  include RequiredFieldValidatorModule 
  include Inactivateable
  include PublicActivity::Common

  acts_as_paranoid # soft delete
  
  OWNERSHIPS = [:agency, :volunteer].freeze

  has_paper_trail

  belongs_to :default_driver, -> { with_deleted }, :class_name => "Driver"
  belongs_to :provider, -> { with_deleted }
  belongs_to :garage_address, -> { with_deleted }, class_name: 'GarageAddress', foreign_key: 'garage_address_id'
  accepts_nested_attributes_for :garage_address, update_only: true
  
  has_one :device_pool_driver, :dependent => :destroy
  has_one :device_pool, :through => :device_pool_driver

  belongs_to :vehicle_maintenance_schedule_type
  belongs_to :vehicle_type
  
  has_many :documents, as: :documentable, dependent: :destroy, inverse_of: :documentable
  has_many :runs, inverse_of: :vehicle # TODO add :dependent rule
  has_many :trips, through: :runs
  has_many :vehicle_maintenance_events, dependent: :destroy, inverse_of: :vehicle
  has_many :vehicle_warranties, dependent: :destroy, inverse_of: :vehicle
  has_many :vehicle_compliances, dependent: :delete_all, inverse_of: :vehicle

  # We must specify :delete_all in order to avoid the before_destroy hook. See
  # the RecurringComplianceEvent concern for more details. 
  # TODO Look into using `#mark_for_destruction` and `#marked_for_destruction?`
  has_many :vehicle_maintenance_compliances, dependent: :delete_all, inverse_of: :vehicle

  validates :provider, presence: true
  validates :name, presence: true, uniqueness: { :case_sensitive => false, scope: :provider, message: "should be unique", conditions: -> { where(deleted_at: nil) } }
  validates :license_plate, uniqueness: { :case_sensitive => false, scope: :provider, message: "should be unique", conditions: -> { where(deleted_at: nil) } }, allow_nil: true, allow_blank: true
  validates :vin, uniqueness: { :case_sensitive => false, scope: :provider, message: "should be unique", conditions: -> { where(deleted_at: nil) } }, length: {is: 17},
    format: {with: /\A[^ioq]*\z/i}, allow_nil: true, allow_blank: true
  validates_date :registration_expiration_date, allow_blank: true
  validates :ownership, inclusion: { in: OWNERSHIPS.map(&:to_s), allow_blank: true }
  validates :initial_mileage, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10000000 }
  validate  :valid_phone_number

  normalize_attribute :name, :vin, :license_plate, :with => [ :strip ]
  
  scope :for_provider,  -> (provider_id) { where(provider_id: provider_id) }
  scope :reportable,    -> { where(reportable: true) }
  scope :is_5310_reportable,    -> { where(is_5310_reportable: true) }
  scope :default_order, -> { order(Arel.sql("lower(name)")) }

  after_initialize :set_defaults

  def self.unassigned(provider)
    for_provider(provider).reject { |vehicle| vehicle.device_pool.present? }
  end

  def self.update_monthly_tracking
    Provider.active.pluck(:id).each do |p_id|
      date = Date.yesterday
      available_vehicle_count = Vehicle.for_provider(p_id).active_for_date(date).count
      tracking_rec = VehicleMonthlyTracking.where(provider_id: p_id, year: date.year, month: date.month).first_or_initialize
      if !tracking_rec.max_available_count || tracking_rec.max_available_count < available_vehicle_count
        tracking_rec.max_available_count = available_vehicle_count
        tracking_rec.save(validate: false)
      end
    end
  end

  def last_odometer_reading
    associated_runs = runs.where().not(end_odometer: nil)
    # if no existing run has logged odometer, then use initial mileage
    last_odometer = if associated_runs.empty?
      initial_mileage
    else
      associated_runs.last.try(:end_odometer)
    end

    last_odometer.to_i
  end

  def compliant?(as_of: Date.current)
    !vehicle_maintenance_compliances.has_overdue?(as_of: as_of) && vehicle_compliances.overdue(as_of: as_of).empty?
  end  

  def expired?(as_of: Date.current)
    vehicle_warranties.expired(as_of: as_of).any?
  end

  private

  def set_defaults
    self.active = true if self.active.nil?
    self.is_5310_reportable = true if self.is_5310_reportable.nil?
  end

  def valid_phone_number
    util = Utility.new
    if garage_phone_number.present?
      errors.add(:garage_phone_number, 'is invalid') unless util.phone_number_valid?(garage_phone_number) 
    end
  end
end
