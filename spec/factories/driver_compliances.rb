FactoryGirl.define do
  factory :driver_compliance do
    driver
    event { Faker::Lorem.words(2).join(' ') }
    due_date { Date.current.tomorrow }
    
    trait :complete do
      compliance_date { Date.current }
    end

    trait :recurring do
      after(:build) do |dc|
        dc.recurring_driver_compliance = create :recurring_driver_compliance, provider: dc.driver.provider
      end
    end
  end
end
