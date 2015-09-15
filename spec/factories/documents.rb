FactoryGirl.define do
  factory :document, aliases: [:driver_document] do
    description { Faker::Lorem.words(2).join(' ') }
    
    # Avoid using fixture_file_upload with FactoryGirl and Paperclip
    # http://goo.gl/jBc5lS
    document_file_name { 'test.pdf' }
    document_content_type { 'application/pdf' }
    document_file_size { 1024 }
    document_updated_at { Time.current }
    
    association :documentable, factory: :driver
    
    trait :no_attachment do
      document_file_name nil
      document_content_type nil
      document_file_size nil
      document_updated_at nil
    end
    
    factory :vehicle_document do
      association :documentable, factory: :vehicle
    end
  end
end
