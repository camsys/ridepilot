class DriverCompliance < ActiveRecord::Base
  include DocumentAssociable
  include ComplianceEvent
  include RecurringComplianceEvent
  
  belongs_to :driver, inverse_of: :driver_compliances
  belongs_to :recurring_driver_compliance, inverse_of: :driver_compliances
  
  validates :driver, presence: true
  validates_date :due_date
  
  scope :for_driver, -> (driver_id) { where(driver_id: driver_id) }
  scope :overdue, -> (as_of: Date.current) { incomplete.where("due_date < ?", as_of) }
  scope :due_soon, -> (as_of: Date.current, through: nil) { incomplete.where(due_date: as_of..(through || as_of + 6.days)) }
  scope :default_order, -> { order("due_date DESC") }

  # Only used internally, but public for testability
  def self.editable_occurrence_attributes
    [:compliance_date]
  end
  
  # Only used internally, but public for testability
  def is_recurring?
    recurring_driver_compliance.present?
  end
end
