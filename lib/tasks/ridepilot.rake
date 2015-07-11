namespace :ridepilot do

  #------------- Incremental Seeding ------------------
  desc 'Seed default lookup tables and configurations'
  task :seed_lookup_tables => :environment do
    puts 'trip purposes...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_trip_purposes.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding trip purposes'

    puts 'trip results...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_trip_results.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding trip results'

    puts 'service levels...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_service_levels.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding service levels'

    puts 'lookup table configurations...'
    seed_file = File.join(Rails.root, 'db', 'tasks', 'seed_lookup_table_configurations.rb')
    load(seed_file) if File.exist?(seed_file)
    puts 'Finished seeding lookup table configurations'
  end

  #------------- End of Incremental Seeding --------------
end
