# Cron job scheduler. Integrates with Capistrano, or update your custom 
# deployments to manually execute whenever 'bundle exec whenever --update-crontab'. 
# See `bundle exec whenever --help` for details

every 1.day, :at => '12:00 am' do
  rake "scheduler:run"
end
