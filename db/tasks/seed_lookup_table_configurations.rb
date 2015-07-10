[
  {
    name: 'TripPurpose',
    caption: 'Trip Purpose',
    value_column_name: 'name'
  },
  {
    name: 'TripResult',
    caption: 'Trip Result',
    value_column_name: 'name',
    add_value_allowed: false,
    delete_value_allowed: false
  },
  {
    name: 'ServiceLevel',
    caption: 'Service Level',
    value_column_name: 'name'
  },
  {
    name: 'Mobility',
    caption: 'Mobility Requirement',
    value_column_name: 'name'
  }
].each do | config_data|
  config = LookupTable.find_by(name: config_data[:name])
  if config 
    config.update_attributes(config_data)
  else
    LookupTable.create(config_data)
  end
end