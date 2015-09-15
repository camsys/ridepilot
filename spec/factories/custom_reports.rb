FactoryGirl.define do
  factory :custom_report do
    title { Faker::Lorem.words(2).join(' ') }
    name { Faker::Lorem.words(2).join(' ') }
    redirect_to_results false
  end

end
