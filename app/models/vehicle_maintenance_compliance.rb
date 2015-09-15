class VehicleMaintenanceCompliance < ActiveRecord::Base
  include DocumentAssociable
  include ComplianceEvent
  include RecurringComplianceEvent

  DUE_TYPES = [:date, :mileage, :both].freeze
  
  belongs_to :vehicle, inverse_of: :vehicle_maintenance_compliances
  belongs_to :recurring_vehicle_maintenance_compliance, inverse_of: :vehicle_maintenance_compliances
  
  validates :vehicle, presence: true
  validates :due_type, inclusion: { in: DUE_TYPES.map(&:to_s) }
  validates :due_date, presence: { if: :due_date_required? }
  validates_date :due_date, allow_blank: true
  validates :due_mileage, presence: { if: :due_mileage_required? }
  validates :due_mileage, numericality: { only_integer: true, greater_than: 0, allow_blank: true }
  validates :compliance_date, presence: { if: -> { self.compliance_mileage.present? } }
  validates :compliance_mileage, presence: { if: -> { self.compliance_date.present? } }, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
  
  scope :for_vehicle, -> (vehicle_id) { where(vehicle_id: vehicle_id) }
  scope :default_order, -> { order("due_date IS NULL, due_date DESC, due_mileage DESC") }
  
  # NOTE These 2 scopes rely on data from vehicles and runs
  # RADAR change to pure SQL if this routinely operates on large sets
  scope :overdue, -> (as_of: Date.current) { where(id: incomplete.select{ |r| r.overdue?(as_of: as_of) }.collect(&:id)) }
  scope :due_soon, -> (as_of: Date.current, through: nil, within_mileage: 500) { where(id: incomplete.select{ |r|  r.overdue?(as_of: as_of..(through || as_of + 6.days), mileage: r.vehicle_odometer_reading..(r.vehicle_odometer_reading + within_mileage)) }.collect(&:id)) }
  
  def overdue?(as_of: Date.current, mileage: vehicle_odometer_reading)
    case due_type.to_sym
    when :date
      is_after_due_date? as_of
    when :mileage
      is_over_due_mileage? mileage
    when :both
      is_after_due_date?(as_of) && is_over_due_mileage?(mileage)
    end
  end
  
  def vehicle_odometer_reading
    vehicle.last_odometer_reading
  end
  
  # Only used internally, but public for testability
  def self.editable_occurrence_attributes
    [:compliance_date, :compliance_mileage]
  end
  
  # Only used internally, but public for testability
  def is_recurring?
    recurring_vehicle_maintenance_compliance.present?
  end

  private
  
  def is_after_due_date?(as_of)
    if as_of.is_a? Range
      as_of.include? due_date
    else
      as_of > due_date
    end
  end
  
  def is_over_due_mileage?(mileage)
    if mileage.is_a? Range
      mileage.include? due_mileage
    else
      mileage > due_mileage
    end
  end
  
  def due_date_required?
    [:both, :date].include? due_type.try(:to_sym)
  end
  
  def due_mileage_required?
    [:both, :mileage].include? due_type.try(:to_sym)
  end
end
