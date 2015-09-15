FactoryGirl.define do
  factory :driver_history do
    driver
    event { Faker::Lorem.words(2).join(' ') }
    event_date { Date.current }
  end
end
