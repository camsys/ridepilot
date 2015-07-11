FactoryGirl.define do
  factory :trip do
    association :pickup_address, factory: :address
    association :dropoff_address, factory: :address
    pickup_time { Time.now + 1.week }
    appointment_time { pickup_time + 30.minutes }
    trip_purpose
    customer
    
    factory :cab_trip do
      cab true
    end
  end
end
