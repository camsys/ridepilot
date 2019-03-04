[
  {
    name: 'provider_service_productivity_report',
    title: 'Provider Service Productivity Report'
  },
  {
    name: 'vehicle_monthly_service_report',
    title: 'Vehicle Monthly Service Report'
  },
  {
    name: 'driver_monthly_service_report',
    title: 'Driver Monthly Service Report'
  },
  {
    name: 'cancellations_report',
    title: 'Cancellations, No Show or Missed Trip Report'
  },
  {
    name: 'driver_report',
    title: 'Driver Report'
  },
  {
    name: 'driver_compliances_report',
    title: 'Driver Compliances Report'
  },
  {
    name: 'inactive_driver_status_report',
    title: 'Inactive Driver Status Report'
  },
  {
    name: 'vehicle_report',
    title: 'Vehicle Report'
  },
  {
    name: 'vehicle_5310_report',
    title: 'FTA 5310 Vehicle Report'
  },
  {
    name: 'provider_common_location_report',
    title: 'Provider Common Location Report'
  },
  {
    name: 'customers_report',
    title: 'Customers Report'
  },
  {
    name: 'ineligible_customer_status_report',
    title: 'Ineligible Customer Status Report'
  },
  {
    name: 'customer_donation_report',
    title: 'Customer Donation Report'
  },
  {
    name: 'missing_data_report',
    title: 'Missing Data Report'
  },
  {
    name: 'manifest',
    title: 'Manifest'
  },
  {
    name: 'ntd',
    title: 'National Transit Database (NTD) '
  },
  {
    name: 'pre_run_inspections',
    title: 'Pre-run Inspections'
  }].each do |report_data|
  report = CustomReport.where(name: report_data[:name], version: '2').first_or_create 
  report.update(redirect_to_results: true, title: report_data[:title])
end