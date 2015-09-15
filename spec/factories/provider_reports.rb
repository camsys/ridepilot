FactoryGirl.define do
  factory :provider_report do
    provider
    custom_report
    inactive false
  end

end
