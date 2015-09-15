FactoryGirl.define do
  factory :lookup_table do
    caption "Trip Purpose"
    name "TripPurpose"
    value_column_name "name"
    add_value_allowed true
    edit_value_allowed true
    delete_value_allowed true
  end

end
