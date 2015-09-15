FactoryGirl.define do
  factory :recurring_vehicle_maintenance_compliance do
    provider
    event_name { Faker::Lorem.words(2).join(' ') }
    recurrence_type "date"
    recurrence_schedule "months"
    recurrence_frequency 1
    start_date { Date.current }
    future_start_rule "immediately"
  end
end
