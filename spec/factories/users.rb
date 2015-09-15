require 'faker'

FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    password 'password#1'
    password_confirmation {|u| u.password}
    association :current_provider, factory: :provider
    
    factory :editor do
      after(:create) do |editor|
        create(:role, :user => editor, :provider => editor.current_provider, :level => 50) unless editor.roles.any?
      end
    end
    
    ##
    # Our feature and controller tests will mostly use this role when logging 
    # in, but note that many actions are therefore restricted to objects that 
    # share the same provider_id
    #
    factory :admin do
      after(:create) do |admin|
        create(:role, :user => admin, :provider => admin.current_provider, :level => 100) unless admin.roles.any?
      end
    end
    
    ##
    # Super admins can manage ANY record, so use in controller and feature tests
    # sparingly, or when you're explicitly testing super admin functionality
    # 
    factory :super_admin do      
      after(:create) do |super_admin|
        create(:role, :user => super_admin, :provider => super_admin.current_provider, :level => 200) unless super_admin.roles.any?
      end
    end
  end
end
