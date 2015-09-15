require 'rails_helper'

RSpec.describe DocumentAssociation, type: :model do
  it "requires a document" do
    association = build :document_association, document: nil
    expect(association.valid?).to be_falsey
    expect(association.errors.keys).to include :document
  end

  it "requires an associable object" do
    association = build :document_association, associable: nil
    expect(association.valid?).to be_falsey
    expect(association.errors.keys).to include :associable
  end
  
  it "requires that the document and associable share the same parent object" do
    document = create :document
    associable = create :driver_compliance
    association = build :document_association, document: document, associable: associable, allow_invalid_owners: true
    expect(association.valid?).to be_falsey
    expect(association.errors.keys).to include :base
    
    association.associable.update_attribute :driver, document.documentable
    expect(association.valid?).to be_truthy
  end
  
  it "restricts documents from being assigned to the same associable more than once" do
    document = create :document
    associable_1 = create :driver_compliance, driver: document.documentable
    associable_2 = create :driver_compliance, driver: document.documentable
    create :document_association, document: document, associable: associable_1
    association = build :document_association, document: document, associable: associable_1
    
    expect(association.valid?).to be_falsey
    expect(association.errors.keys).to include :document_id
    
    association.associable = associable_2
    expect(association.valid?).to be_truthy
  end
end
