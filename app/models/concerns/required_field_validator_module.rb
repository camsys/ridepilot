require 'active_support/concern'

module RequiredFieldValidatorModule
  extend ActiveSupport::Concern

  included do
    def is_all_valid?(provider_id)
      base_valid = valid?
      custom_valid = true
      required_fields = self.class.required_field_names(provider_id)
      required_fields.each do |field_name|
        if !self.try(field_name).present? 
          custom_valid = false
          self.errors[field_name] << " is required."
        end
      end

      base_valid && custom_valid
    end
  end

  module ClassMethods 
    def required_field_names(provider_id)
      FieldConfig.per_table(provider_id, table_name).required_fields.pluck(:field_name)
    end
  end
end