# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

ActiveRecord::Base.transaction do
  puts "Seeding..."

  puts "Creating first provider and system admin..."
  if !Provider.first.present?
    puts "Creating first Provider UTA..."
    provider = Provider.new(:name => 'UTA', :dispatch => true)
    #provider.logo = File.open(Rails.root.join("public", "uta_logo.png"))
    provider.save!
  
    puts "Creating first User..."
    password = Rails.application.secrets.system_admin_password
    user = User.create!(
      :email => Rails.application.secrets.system_admin_email,
      :password => password,
      :password_confirmation => password,
      :current_provider => provider
    )
  
    puts "Setting first user up as a super admin..."
    Role.create!(
      :user => user,
      :provider => provider, 
      :level => 200
    )
  end

  puts "Creating lookup tables..."
  Rake::Task["ridepilot:seed_lookup_tables"].invoke

  puts "Seeding translations"
  Rake::Task["ridepilot:load_locales"].invoke

  puts "Seeding custom reports"
  Rake::Task["ridepilot:seed_custom_reports"].invoke

  puts "Done seeding"

end
