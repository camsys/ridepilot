# This is a 'dumb' model. It is managed by a Run instance, which creates a 
# repeating instance of itself when instructed to. Validation is nonexistent 
# since all data should already have been vetted by the Run instance.
class RepeatingRun < ActiveRecord::Base
  include RecurringRideCoordinatorScheduler

  has_paper_trail

  belongs_to :vehicle
  belongs_to :driver
  belongs_to :provider

  def instantiate!
    now = Date.today + 1.day
    later = now.advance(days: 19)
    RepeatingRun.transaction do
      for date in schedule.occurrences_between(now, later)
        unless Run.repeating_based_on(self).for_date(date).exists?
          attributes = self.attributes.select{ |k, v| RepeatingRun.ride_coordinator_attributes.include? k.to_s }
          attributes["date"] = date
          attributes["repeating_run_id"] = id
          attributes["via_recurring_ride_coordinator_scheduler"] = true
          run = Run.new attributes
          # debugger unless run.valid?
          run.save!
        end
      end
    end
  end
end
