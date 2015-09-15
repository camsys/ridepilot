FactoryGirl.define do
  factory :field_config do
    provider
    table_name "MyString"
    field_name "MyString"
    visible false
    required false
  end

end
