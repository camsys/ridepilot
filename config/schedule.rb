# Cron job scheduler. Integrates with Capistrano, or update your custom 
# deployments to manually execute whenever. See `bundle exec whenever --help` 
# for details

every 1.day, :at => '12:00 am' do
  # Schedule repeating trips
  runner "RepeatingTrip.generate!"

  # Schedule repeating runs
  runner "RepeatingRun.generate!"

  # Schedule recurring driver compliance events 5 years out
  runner "RecurringDriverCompliance.generate! date_range_length: 5.years"

  # Schedule recurring vehicle maintenance compliance events 5 years and 30000
  # miles out
  runner "RecurringVehicleMaintenanceCompliance.generate! date_range_length: 5.years, mileage_range_length: 30_000"
end
