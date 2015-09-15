FactoryGirl.define do
  factory :repeating_run do
    date { Date.today }
    vehicle
    driver
    provider
  end
end
