class RepeatingTrip < ActiveRecord::Base
  include ScheduleAttributes

  belongs_to :provider
  belongs_to :customer
  belongs_to :pickup_address, :class_name=>"Address"
  belongs_to :dropoff_address, :class_name=>"Address"
  belongs_to :repeating_trip
  belongs_to :trip_purpose

  validates_date :pickup_time
  validates_date :appointment_time

  has_paper_trail

  NON_TRIP_ATTRIBUTES = %w(id recurrence schedule_yaml created_at updated_at lock_version)

  def self.trip_attributes  
    self.new.attributes.keys - NON_TRIP_ATTRIBUTES
  end

  #Create concrete trips from all repeating trips.  This method
  #is idempotent.
  def self.create_trips
    for repeating_trip in RepeatingTrip.all
      repeating_trip.instantiate
    end
  end

  def pickup_time=(datetime)
    write_attribute :pickup_time, format_datetime( datetime )
  end
  
  def appointment_time=(datetime)
    write_attribute :appointment_time, format_datetime( datetime )
  end

  def instantiate
    now = Date.today + 1.day
    later = now.advance(:days=>20) 
    for date in schedule.occurrences_between(now, later)
      this_trip_pickup_time = Time.zone.local(date.year, date.month, date.day, pickup_time.hour, pickup_time.min, pickup_time.sec)
      
      unless Trip.repeating_based_on(self).for_date(date).exists?
        attributes = self.attributes
        NON_TRIP_ATTRIBUTES.each {|attr| attributes.delete(attr)}
        attributes["repeating_trip_id"] = id
        attributes["pickup_time"] = this_trip_pickup_time
        attributes["appointment_time"] = this_trip_pickup_time + (appointment_time - pickup_time)
        attributes["via_repeating_trip"] = true
        Trip.new(attributes).save!
      end
    end
  end

  private
  
  def format_datetime(datetime)
    if datetime.is_a?( String ) 
      if %w{a p}.include?( datetime.last.downcase ) 
        Time.parse("#{datetime}m")
      else
        Time.parse(datetime)
      end
    else
      datetime
    end
  end
end
