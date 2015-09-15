class Provider < ActiveRecord::Base
  acts_as_paranoid # soft delete
  
  serialize :fields_required_for_run_completion, Array

  has_many :addresses, :dependent => :nullify
  has_many :device_pools, :dependent => :destroy
  has_many :drivers, :dependent => :destroy
  has_many :ethnicities, :class_name=>'ProviderEthnicity', :dependent => :destroy
  has_many :funding_sources, :through => :funding_source_visibilities
  has_many :funding_source_visibilities, :dependent => :destroy
  has_many :monthlies, :dependent => :destroy
  has_many :provider_reports
  has_many :recurring_driver_compliances, :dependent => :destroy
  has_many :recurring_vehicle_maintenance_compliances, :dependent => :destroy
  has_many :reports, through: :provider_reports
  has_many :roles, :dependent => :destroy
  has_many :users, :through => :roles
  has_many :vehicles, :dependent => :destroy

  has_one :address_upload_flag

  has_attached_file :logo, :styles => { :small => "150x150>" }
  
  REIMBURSEMENT_ATTRIBUTES = [
    :oaa3b_per_ride_reimbursement_rate,
    :ride_connection_per_ride_reimbursement_rate,
    :trimet_per_ride_reimbursement_rate,
    :stf_van_per_ride_reimbursement_rate,
    :stf_taxi_per_ride_administrative_fee,
    :stf_taxi_per_ride_ambulatory_load_fee,
    :stf_taxi_per_ride_wheelchair_load_fee,
    :stf_taxi_per_mile_ambulatory_reimbursement_rate,
    :stf_taxi_per_mile_wheelchair_reimbursement_rate
  ]
  
  validates :name, :length => { :minimum => 2 }
  validates_numericality_of :oaa3b_per_ride_reimbursement_rate,               :greater_than => 0, :allow_blank => true
  validates_numericality_of :ride_connection_per_ride_reimbursement_rate,     :greater_than => 0, :allow_blank => true
  validates_numericality_of :trimet_per_ride_reimbursement_rate,              :greater_than => 0, :allow_blank => true
  validates_numericality_of :stf_van_per_ride_reimbursement_rate,             :greater_than => 0, :allow_blank => true
  validates_numericality_of :stf_taxi_per_ride_administrative_fee,            :greater_than => 0, :allow_blank => true
  validates_numericality_of :stf_taxi_per_ride_ambulatory_load_fee,           :greater_than => 0, :allow_blank => true
  validates_numericality_of :stf_taxi_per_ride_wheelchair_load_fee,           :greater_than => 0, :allow_blank => true
  validates_numericality_of :stf_taxi_per_mile_ambulatory_reimbursement_rate, :greater_than => 0, :allow_blank => true
  validates_numericality_of :stf_taxi_per_mile_wheelchair_reimbursement_rate, :greater_than => 0, :allow_blank => true
  validates_attachment      :logo,
    size: {:less_than => 200.kilobytes}, 
    # prevent content-type spoofing:
    content_type: {:content_type => /\Aimage/},
    file_name: {:matches => [/png\Z/, /gif\Z/, /jpe?g\Z/], allow_blank: true}
  validate                  :fields_required_for_run_completion_includes_allowed_values
  
  after_initialize :init

  def init
    self.scheduling = true if new_record?
  end

  def address_upload_flag
    super || AddressUploadFlag.create(provider: self)
  end
  
  def fields_required_for_run_completion_includes_allowed_values
    errors.add(:fields_required_for_run_completion, "contains invalid attribute values") if fields_required_for_run_completion.is_a?(Array) && (fields_required_for_run_completion.map(&:to_s) - Run::FIELDS_FOR_COMPLETION.map(&:to_s)).any?
  end
end
