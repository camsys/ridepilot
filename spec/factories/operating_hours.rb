FactoryGirl.define do
  factory :operating_hours do
    day_of_week 0
    start_time "00:00:00"
    end_time "23:59:59"
    driver
  end
end
