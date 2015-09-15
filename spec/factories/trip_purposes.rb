FactoryGirl.define do
  factory :trip_purpose do
    name {|n| "sample_purpose_#{n}" }
  end

end
