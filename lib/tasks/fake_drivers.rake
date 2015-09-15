PERIOD = 15 # Seconds between updates

namespace :test do
  desc "Move fake drivers around on the map."
  task :fake_drivers, [:provider_id] => :environment do |t, args|
    drivers = get_drivers(args[:provider_id])
    begin
      move_drivers drivers
    rescue Interrupt
      deactivate_drivers drivers
    end
    puts "\nDone."
  end

  def get_drivers(provider_id)
    if provider_id.nil?
      raise "Please specify a provider id, e.g.:\nrake test:fake_drivers[1]"
    end
    if not Provider.exists?(provider_id)
      raise "Provider #{provider_id} does not exist."
    end
    pools = DevicePool.where(:provider_id => provider_id)
    if pools.length == 0
      raise "No device pools belonging to that provider. Nothing to do."
    end
    drivers = DevicePoolDriver.where(:device_pool_id => pools)
    if drivers.length == 0
      raise "No drivers in provider's device pool(s). Nothing to do."
    end
    return drivers
  end

  def move_drivers(drivers)
    puts 'Moving drivers. (CTRL-C to interrupt)'
    while true do
      drivers.each do |driver|
        driver.status = 'active'
        if driver.lat.blank? then driver.lat = GOOGLE_MAP_DEFAULTS[:viewport][:center_lat].to_s end
        if driver.lng.blank? then driver.lng = GOOGLE_MAP_DEFAULTS[:viewport][:center_lng].to_s end
        # Move a small random amount
        lat_offset = (Random.rand(20)-10)/1000.0
        lng_offset = (Random.rand(20)-10)/1000.0
        lat = driver.lat.to_f + lat_offset
        lng = driver.lng.to_f + lng_offset
        # Bounce back to center if it goes too far
        if lat > GOOGLE_MAP_DEFAULTS[:bounds][:north] or lat < GOOGLE_MAP_DEFAULTS[:bounds][:south] then lat = GOOGLE_MAP_DEFAULTS[:viewport][:center_lat] end
        if lng > GOOGLE_MAP_DEFAULTS[:bounds][:east] or lng < GOOGLE_MAP_DEFAULTS[:bounds][:west] then lng = GOOGLE_MAP_DEFAULTS[:viewport][:center_lng] end
        driver.lat = lat.to_s
        driver.lng = lng.to_s
        driver.posted_at = DateTime.now
        driver.save!
      end
      print '.'
      sleep(PERIOD)
    end
  end

  def deactivate_drivers(drivers)
    print "\nDeactivating drivers"
    DevicePoolDriver.all.each do |driver|
      driver.status = "inactive"
      driver.posted_at = DateTime.now
      driver.save!
       print '.'
    end
  end
end
