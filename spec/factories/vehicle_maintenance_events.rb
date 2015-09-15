FactoryGirl.define do
  factory :vehicle_maintenance_event do
    vehicle
    service_date { Date.current }
    services_performed { Faker::Lorem.words(6).join(', ') }
  end
end
