class CustomReport < ActiveRecord::Base
  has_many :provider_reports
  has_many :providers, through: :provider_reports

  validates :name, presence: true, uniqueness: true

  scope :active_per_provider, -> (provider_id) { 
    includes(:provider_reports).references(:provider_reports)
    .where("provider_reports.provider_id is NULL or (provider_reports.provider_id = ? and provider_reports.inactive = ?)", provider_id, false)
  }

  def display_name
    title || name.titleize
  end
end
