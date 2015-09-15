FactoryGirl.define do
  factory :vehicle do
    name { Faker::Lorem.words(2).join(' ') }
    provider
    association :default_driver, factory: :driver
    seating_capacity 10
  end
end
