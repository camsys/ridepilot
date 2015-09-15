[
  {
    name: 'trip_purposes',
    caption: 'Trip Purpose',
    value_column_name: 'name'
  },
  {
    name: 'trip_results',
    caption: 'Trip Result',
    value_column_name: 'name',
    add_value_allowed: false,
    delete_value_allowed: false
  },
  {
    name: 'service_levels',
    caption: 'Service Level',
    value_column_name: 'name'
  },
  {
    name: 'mobilities',
    caption: 'Mobility Requirement',
    value_column_name: 'name'
  },
  {
    name: 'funding_sources',
    caption: 'Funding Source',
    value_column_name: 'name'
  },
  {
    name: 'provider_ethnicities',
    caption: 'Provider Ethnicity',
    value_column_name: 'name',
    is_provider_specific: true
  }
].each do | config_data|
  config = LookupTable.find_by(name: config_data[:name])
  if config 
    config.update_attributes(config_data)
  else
    LookupTable.create(config_data)
  end
end