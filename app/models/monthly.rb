class Monthly < ActiveRecord::Base
  
  belongs_to :provider
  belongs_to :funding_source

  validates_presence_of :provider
  validates_presence_of :funding_source
  validates_datetime :start_date
  validates_numericality_of :volunteer_escort_hours, greater_than_or_equal_to: 0, allow_blank: true
  validates_numericality_of :volunteer_admin_hours, greater_than_or_equal_to: 0, allow_blank: true
  validates_uniqueness_of :start_date, scope: [:provider_id, :funding_source_id], message: "has already been used for the given provider and funding source"

  has_paper_trail
  
  # Ensure that the start date represents the first of any given month
  def start_date=(start_date)
    parsed_date = Date.parse(start_date) rescue nil
    if parsed_date.is_a? Date
      write_attribute :start_date, parsed_date.beginning_of_month
    else
      # Let the validation methods take care of it
      write_attribute :start_date, start_date
    end
  end
end
