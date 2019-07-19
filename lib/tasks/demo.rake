
namespace :demo do
  desc "delete previous demo provider"
  task clean: :environment do
    Provider.where(name: 'Demo', admin_name: 'Demo Admin').destroy_all
  end

  desc "setup new demo data"
  task setup: :environment do
    steps = [
      "new_provider",
      "configure_users",
      "configure_drivers",
      "configure_vehicles",
      "configure_customers",
      "configure_trips",
      "configure_runs",
      "dispatch"
    ]
    steps.each do |step|
      Rake::Task["demo:#{step}"].invoke
    end

    puts 'data setup finished'
  end

  desc "create new demo provider named Demo"
  task new_provider: :environment do 
    provider = Provider.where(name: 'Demo', admin_name: 'Demo Admin').first_or_create

    ##### GENERAL #####

    # provider operating hours: M-F, 7am - 7pm
    provider.operating_hours.delete_all
    (1..5).each do |day_of_week|
      provider.operating_hours.create day_of_week: day_of_week, start_time: "07:00:00", end_time: "19:00:00"
    end

    # Region Boundaries
    provider.region_nw_corner = Address.compute_geom(42.49057, -71.18635)
    provider.region_se_corner = Address.compute_geom(42.243919, -71.003714)
    provider.save
  end

  task configure_users: :environment do 
    provider = Provider.where(name: 'Demo', admin_name: 'Demo Admin').first

    existing_user_ids = provider.roles.pluck(:user_id)
    User.where(id: existing_user_ids).delete_all
    provider.roles.delete_all

    ##### USERS #####
    # provider admin
    prod_admin = User.find_by_email("demo_admin@example.com")
    unless prod_admin
      prod_admin = User.new(email: "demo_admin@example.com", 
          username: "demo_admin", 
          first_name: "Admin", 
          last_name: "User")
      prod_admin.password = "Welcome1!"
      prod_admin.password_confirmation = "Welcome1!"
    end
    prod_admin.current_provider = provider
    prod_admin.save
    Role.create(provider: provider, user: prod_admin, level: Role::ADMIN_LEVEL)

    # editor / dispatcher
    editor = User.find_by_email("demo_dispatcher@example.com")
    unless editor
      editor = User.new(email: "demo_dispatcher@example.com", 
        username: "demo_dispatcher",
        first_name: "Dispatcher", 
        last_name: "User")
      editor.password = "Welcome1!"
      editor.password_confirmation = "Welcome1!"
    end
    editor.current_provider = provider
    editor.save
    Role.create(provider: provider, user: editor, level: Role::EDITOR_LEVEL)

    # driver
    driver = User.find_by_email("demo_driver@example.com")
    unless driver
      driver = User.new(email: "demo_driver@example.com", 
          username: "demo_driver",
          first_name: "Driver", 
          last_name: "User")
      driver.password = "Welcome1!"
      driver.password_confirmation = "Welcome1!"
    end
    driver.current_provider = provider
    driver.save
    Role.create(provider: provider, user: driver, level: Role::USER_LEVEL)
  end

  task configure_drivers: :environment do 
    provider = Provider.where(name: 'Demo', admin_name: 'Demo Admin').first
    driver_user = User.find_by_email("demo_driver@example.com")

    Driver.where(user:driver_user).delete_all

    driver = Driver.new(user: driver_user, provider: provider, phone_number: "(888) 123-4567")
    driver.build_address(name: "Office", address: "101 Station Landing", city: "Medford", state: "MA", zip: "02155", provider: provider)
    driver.save

    # configure driver availability:M-F, 7am - 7pm
    driver.operating_hours.delete_all
    (1..5).each do |day_of_week|
      driver.operating_hours.create day_of_week: day_of_week, start_time: "07:00:00", end_time: "19:00:00"
    end
  end

  task configure_vehicles: :environment do 
    provider = Provider.where(name: 'Demo', admin_name: 'Demo Admin').first

    # Capacity Type
    seat_ct = CapacityType.where(name: 'Seat').first_or_create
    floor_ct = CapacityType.where(name: 'Floor').first_or_create

    # Vehicle types: Demo Sedan
    VehicleType.where(provider: provider).delete_all
    demo_sedan = VehicleType.create(name: 'Sedan', provider: provider)
    config_1 = demo_sedan.vehicle_capacity_configurations.new
    config_1.vehicle_capacities.new(capacity_type: seat_ct, capacity: 4)
    config_1.vehicle_capacities.new(capacity_type: floor_ct, capacity: 0)
    config_1.save
    config_2 = demo_sedan.vehicle_capacity_configurations.new
    config_2.vehicle_capacities.new(capacity_type: seat_ct, capacity: 3)
    config_2.vehicle_capacities.new(capacity_type: floor_ct, capacity: 1)
    config_2.save

    # Vehicle
    Vehicle.where(provider: provider).delete_all
    demo_vehicle = Vehicle.create(name: 'Sedan #1', vehicle_type: demo_sedan, provider: provider)

    # vehicle garage address
    garage_address = GarageAddress.new(address: '80 Station Landing', city: "Medford", state: "MA", zip: "02155", provider: provider)
    garage_address.the_geom = Address.compute_geom(42.4025765, -71.08047879999998)
    garage_address.save
    demo_vehicle.garage_address = garage_address
    demo_vehicle.save

    VehicleInspection.where(provider: provider).delete_all
    ["Fuel tank is full.", "Tires are inflated to proper pressure."].each do |insp|
      VehicleInspection.create(provider: provider, description: insp)
    end
  end

  task configure_customers: :environment do 
    provider = Provider.where(name: 'Demo', admin_name: 'Demo Admin').first

    Customer.where(provider: provider).delete_all
    john_doe = Customer.new(provider: provider, first_name: 'John', last_name: 'Doe', public_notes: "please park close to the curb")

    # addresses
    office = john_doe.addresses.new(name: "Office", address: "101 Station Landing", city: "Medford", state: "MA", zip: "02155", in_district: true, provider: provider)
    office.the_geom = Address.compute_geom(42.4019594, -71.0812455999999)
    home_addr = john_doe.addresses.new(name: "Home", address: "Porter Square", city: "Cambridge", state: "MA", zip: "02155", in_district: true, provider: provider)
    home_addr.the_geom = Address.compute_geom(42.3888566, -71.11939819999998)

    john_doe.addresses = [office, home_addr]
    john_doe.address = home_addr
    john_doe.save

    # mobilities
    customer_ridership_id = 1
    service_animal_ridership_id = 4

    ambulatory_mobility_id = Mobility.find_by_name('Ambulatory').try(:id)
    floor_animal_mobility_id = Mobility.find_by_name('Floor animal').try(:id)
    john_doe.ridership_mobilities.create(ridership_id: customer_ridership_id, mobility_id: ambulatory_mobility_id, capacity: 1) if ambulatory_mobility_id
    john_doe.ridership_mobilities.create(ridership_id: service_animal_ridership_id, mobility_id: floor_animal_mobility_id, capacity: 1) if floor_animal_mobility_id
  end

  task configure_trips: :environment do 
    provider = Provider.where(name: 'Demo', admin_name: 'Demo Admin').first

    # recurring trips
    RepeatingTrip.where(provider: provider).delete_all
    Trip.where(provider: provider).delete_all

    john_doe = Customer.where(provider: provider, first_name: 'John', last_name: 'Doe').first 

    home_addr = john_doe.addresses.find_by_name('Home')
    office_addr = john_doe.addresses.find_by_name('Office')
    work_purpose = TripPurpose.find_by_name("School/Work")

    repeating_outbound = RepeatingTrip.new(
      provider: provider, 
      customer: john_doe, 
      pickup_time: "8:00 AM", 
      appointment_time: "9:00 AM", 
      pickup_address: home_addr,
      dropoff_address: office_addr,
      trip_purpose: work_purpose,
      repeats_mondays: true,
      repeats_tuesdays: true,
      repeats_wednesdays: true,
      repeats_thursdays: true,
      repeats_fridays: true,
      repetition_interval: 1)

    john_doe.ridership_mobilities.has_capacity.each do |rm|
      repeating_outbound.ridership_mobilities << RepeatingTripRidershipMobility.new(ridership_id: rm.ridership_id, mobility_id: rm.mobility_id, capacity: rm.capacity)
    end

    repeating_outbound.save
  end

  task configure_runs: :environment do 
    provider = Provider.where(name: 'Demo', admin_name: 'Demo Admin').first

    # recurring runs
    RepeatingRun.where(provider: provider).delete_all
    Run.where(provider: provider).delete_all

    demo_vehicle = Vehicle.where(name: 'Sedan #1', provider: provider).first
    driver_user = User.find_by_email("demo_driver@example.com")
    driver = Driver.where(user: driver_user, provider: provider).first
    run = RepeatingRun.new(
      provider: provider,
      name: "Office AM Run", 
      vehicle: demo_vehicle, 
      driver: driver, 
      scheduled_start_time: "7:30 AM", 
      scheduled_end_time: "11:00 AM",
      repeats_mondays: true,
      repeats_tuesdays: true,
      repeats_wednesdays: true,
      repeats_thursdays: true,
      repeats_fridays: true,
      repetition_interval: 1,
      paid: false)

    run.save
  end

  task dispatch: :environment do 
    provider = Provider.where(name: 'Demo', admin_name: 'Demo Admin').first

    run = RepeatingRun.where(provider: provider, name: 'Office AM Run').first 
    run.weekday_assignments.clear
    run.repeating_run_manifest_orders.clear
    run.repeating_itineraries.clear

    trip = RepeatingTrip.where(provider: provider).first
    (1..5).each do |wday|
      RecurringTripScheduler.new(trip.id, run.id, wday).execute
    end

    Run.today_and_future.where(provider: provider).batch_update_recurring_trip_assignment!
  end

end
