require 'spec_helper'

# For model specs
RSpec.shared_examples "a compliance event" do
  before do
    @described_class_factory = described_class.name.underscore.to_sym
  end
  
  it "requires an event name" do
    compliance = build @described_class_factory, event: nil
    expect(compliance.valid?).to be_falsey
    expect(compliance.errors.keys).to include :event
  end

  it "requires compliance date to be on or before today, when specified" do
    compliance = build @described_class_factory, compliance_date: nil
    expect(compliance.valid?).to be_truthy

    compliance = build @described_class_factory, :complete, compliance_date: Date.current.tomorrow
    expect(compliance.valid?).to be_falsey
    expect(compliance.errors.keys).to include :compliance_date

    compliance = build @described_class_factory, :complete, compliance_date: Date.current
    expect(compliance.valid?).to be_truthy
  end

  describe "#complete?" do
    it "knows if the record is considered complete" do
      compliance = create @described_class_factory
      expect(compliance.complete?).to be_falsey

      compliance = create @described_class_factory, :complete
      expect(compliance.reload.complete?).to be_truthy
    end
  end

  describe ".incomplete" do
    it "finds compliance events that do not have a compliance date" do
      compliance_1 = create @described_class_factory, compliance_date: nil
      compliance_2 = create @described_class_factory, compliance_date: ""
      compliance_3 = create @described_class_factory, :complete

      incomplete = described_class.incomplete
      expect(incomplete).to include compliance_1, compliance_2
      expect(incomplete).not_to include compliance_3
    end
  end
end
