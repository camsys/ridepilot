# This is a 'dumb' model. It is managed by a Trip instance, which creates a 
# repeating instance of itself when instructed to. Validation is nonexistent 
# since all data should already have been vetted by the Trip instance.
class RepeatingTrip < ActiveRecord::Base
  include RecurringRideCoordinatorScheduler

  has_paper_trail

  belongs_to :customer
  belongs_to :driver
  belongs_to :dropoff_address, class_name: "Address"
  belongs_to :funding_source
  belongs_to :mobility
  belongs_to :pickup_address, class_name: "Address"
  belongs_to :provider
  belongs_to :vehicle
  
  def instantiate!
    now = Date.today + 1.day
    later = now.advance(days: 20)
    RepeatingTrip.transaction do
      for date in schedule.occurrences_between(now, later)
        this_trip_pickup_time = Time.zone.local(date.year, date.month, date.day, pickup_time.hour, pickup_time.min, pickup_time.sec)
      
        unless Trip.repeating_based_on(self).for_date(date).exists?
          attributes = self.attributes.select{ |k, v| RepeatingTrip.ride_coordinator_attributes.include? k.to_s }
          attributes["repeating_trip_id"] = id
          attributes["pickup_time"] = this_trip_pickup_time
          attributes["appointment_time"] = this_trip_pickup_time + (appointment_time - pickup_time)
          attributes["via_recurring_ride_coordinator_scheduler"] = true
          trip = Trip.new attributes
          # debugger unless trip.valid?
          trip.save!
        end
      end
    end
  end
end
