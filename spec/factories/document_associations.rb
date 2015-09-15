FactoryGirl.define do
  factory :document_association, aliases: [:driver_compliance_document_association] do
    transient do
      allow_invalid_owners false
    end
  
    document
    association :associable, factory: :driver_compliance

    after(:build) do |da, evaluator|
      # Document and associable must have the same owner
      if !evaluator.allow_invalid_owners and da.document.present? and da.associable.present? and da.associable.associable_owner != da.document.documentable
        da.associable.associable_owner = da.document.documentable
      end
    end
  end
end
