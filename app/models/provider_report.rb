class ProviderReport < ActiveRecord::Base
  belongs_to :provider
  belongs_to :custom_report

  validates :provider, presence: true
  validates :custom_report, presence: true
  validates :custom_report_id, uniqueness: { scope: :provider_id, message: 'One report configuration per provider'}
end
