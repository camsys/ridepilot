# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

ActiveRecord::Base.transaction do
  puts "Seeding..."

  unless Provider.ride_connection.present?
    puts "Creating first Provider..."
    provider = Provider.new(:name => 'Ride Connection', :dispatch => true)
    provider.logo = File.open(Rails.root.join("public", "ride_connection_logo.png"))
    provider.save!
  
    puts "Creating first User..."
    password = Rails.application.secrets.ride_connection_admin_password
    user = User.create!(
      :email => Rails.application.secrets.ride_connection_admin_email,
      :password => password,
      :password_confirmation => password,
      :current_provider => provider
    )
  
    puts "Setting first user up as a super admin..."
    Role.create!(
      :user => user,
      :provider => provider, 
      :level => 100
    )
  end

  Region.find_or_create_by!(:name => "TriMet") do |region|
    puts "Creating TriMet Region..."
    f = File.new(Rails.root.join('db', 'trimet.wkt'))
    wkt = f.read
    f.close
    region.the_geom = RGeo::Geographic.spherical_factory(srid: 4326).parse_wkt(wkt)
  end

  puts "Creating initial mobilities..."
  ["Scooter", "Wheelchair", "Wheelchair - Oversized", "Wheelchair - Can Transfer", "Unknown", "Ambulatory"].each do |name|
    Mobility.find_or_create_by!(:name => name)
  end

  puts "Seeding translations"

  Rake::Task["ridepilot:load_locales"].invoke

  puts "Done seeding"

end
