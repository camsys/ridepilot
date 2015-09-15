[
  {
    name: 'vehicles_monthly',
    title: 'Vehicles'
  },
  {
    name: 'service_summary',
    title: 'Service Summary'
  },
  {
    name: 'donations',
    title: 'Donations'
  },
  {
    name: 'cab',
    title: 'Cab Log'
  },
  {
    name: 'age_and_ethnicity',
    title: 'Age & Ethnicity'
  },
  {
    name: 'monthlies',
    title: 'Monthly Miscellaneous Data'
  }].each do |report_data|
  report = CustomReport.where(name: report_data[:name]).first_or_create 
  report.update(redirect_to_results: true, title: report_data[:title])
end

[
  {
    name: 'show_trips_for_verification',
    title: 'Verify Trips'
  },
  {
    name: 'show_runs_for_verification',
    title: 'Verify Runs'
  },
  {
    name: 'daily_manifest',
    title: 'Daily Manifest'
  },
  {
    name: 'daily_manifest_with_cab',
    title: 'Daily Manifest with Cab Summary'
  },
  {
    name: 'daily_manifest_by_half_hour',
    title: 'Daily Manifest By Half Hour'
  },
  {
    name: 'daily_manifest_by_half_hour_with_cab',
    title: 'Daily Manifest By Half Hour with Cab Summary'
  },
  {
    name: 'daily_trips',
    title: "Day's Trips Report"
  },
  {
    name: 'export_trips_in_range',
    title: 'Export Trips as CSV'
  },
  {
    name: 'customer_receiving_trips_in_range',
    title: 'Customer Trips In Range'
  },
  {
    name: 'cctc_summary_report',
    title: 'Clackamas County Transportation Consortium Summary Report'
  }].each do | report_data |
  report = CustomReport.where(name: report_data[:name]).first_or_create 
  report.update(redirect_to_results: false, title: report_data[:title])
end