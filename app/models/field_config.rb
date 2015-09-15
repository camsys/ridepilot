class FieldConfig < ActiveRecord::Base
  belongs_to :provider

  validates :provider, presence: true
  validates :table_name, presence: true
  validates :field_name, presence: true
  validates :field_name, uniqueness: { scope: [:provider, :table_name], message: 'should be only one field per table and provider' }

  scope :per_table, -> (a_provider_id, a_table_name) { where(provider_id: a_provider_id, table_name: a_table_name) }
  scope :invisible_fields, -> { where(visible: false, required: false) }
  scope :required_fields, -> { where(required: true) }

end
  