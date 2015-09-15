require 'date'

module Reporting::ReportHelper

  def current_provider_id
    current_user.try(:current_provider).try(:id)
  end

  # include both generic reports and customized reports
  def all_report_infos
    
    query_hash = {}

    generic_report_infos = Reporting::Report.all.map {
      |report|
        {
          id: report.id,
          name: report.name,
          is_generic: true
        }
    }


    customized_report_infos = CustomReport.active_per_provider(current_provider_id).map {
      |report|
        {
          id: report.id,
          name: report.display_name,
          is_generic: false
        }
    }

    (generic_report_infos + customized_report_infos).sort_by {|r| r[:name]}
  end

  # converts datetime format to MM/DD/YYYY (to be correctly displayed in front-end)
  def filter_value(raw_value, is_date_field)
    raw_value = Date.strptime(raw_value, "%Y-%m-%d").strftime("%m/%d/%Y") rescue '' if is_date_field
    raw_value || ''
  end

  # find out input type based on field type
  def filter_input_type(field_type)
    case field_type.to_sym
    when :primary_key, :integer, :float, :decimal
      'number'
    else
      'search'
    end
  end

  # format output field value if formatter is configured
  def format_output(raw_value, field_type, formatter = nil, formatter_option = nil)
    unless raw_value.blank? || field_type.blank?
      case field_type.to_sym
      when :date, :datetime
        if field_type == :date
          default_formatter = "%m/%d/%Y" 
        else
          default_formatter = "%m/%d/%Y %H:%M:%S"
        end

        formatter = default_formatter if formatter.blank?
        raw_value = raw_value.strftime(formatter) rescue raw_value.strftime(default_formatter)

      when :integer, :float, :decimal
        formatter_precision = formatter_option.to_i rescue nil if !formatter_option.blank?
        formatter_precision = nil if formatter_precision && formatter_precision < 0 # ignore illegal value
        if !formatter.blank?
          case formatter.lowercase
          when 'currency'
            formatter_precision = 2 if formatter_precision.nil?
            raw_value = number_to_currency(raw_value, precision: formatter_precision)
          when 'percentage'
            formatter_precision = 3 if formatter_precision.nil?
            raw_value = number_to_percentage(raw_value, precision: formatter_precision)
          when 'delimiter'
            raw_value = number_with_precision(raw_value, precision: formatter_precision) if formatter_precision
            raw_value = number_with_delimiter(raw_value)
          when 'phone'
            raw_value = number_to_phone(raw_value)
          when 'human'
            formatter_precision = 3 if formatter_precision.nil?
            raw_value = number_to_human(raw_value, precision: formatter_precision)
          when 'precision'
            formatter_precision = 3 if formatter_precision.nil?
            raw_value = number_with_precision(raw_value, precision: formatter_precision)
          end
        end

      end
    end

    raw_value
  end

  def filter_lookup_table_data(lookup_table)
    return nil if !lookup_table

    data = lookup_table.data_model.order(lookup_table.display_field_name.to_sym)

    data_access_type = lookup_table.data_access_type
    
    unless current_user.super_admin? || data_access_type.blank? || 
      lookup_table.data_model.columns_hash.keys.index(lookup_table.id_field_name).nil?

      # double quote in case field_name is in uppercase
      field_name = "\"#{lookup_table.id_field_name}\""

      if data_access_type.to_sym == :provider
        data = data.where("#{field_name} = ?" , current_provider_id) 
      end
    end

    data
  end

  private

  def report_by_user_role_query_string
    #TODO if needed
  end

end
