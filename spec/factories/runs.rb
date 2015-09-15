FactoryGirl.define do
  factory :run do
    name { Faker::Lorem.words(2).join(' ') }
    date { Date.today }
    vehicle
    driver
    provider
  end
end
