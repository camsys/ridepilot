class FundingSource < ActiveRecord::Base
  acts_as_paranoid # soft delete
  
  has_many :funding_source_visibilities, :dependent => :destroy
  has_many :providers, :through=>:funding_source_visibilities
  validates_presence_of :name
  validates_length_of :name, :minimum=>2

  def self.by_provider(provider)
    return FundingSource.joins(:funding_source_visibilities).where("funding_source_visibilities.provider_id = ?", provider.id)
  end
end
