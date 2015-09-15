require 'spec_helper'

# For model specs
RSpec.shared_examples "a recurring ride coordinator scheduler" do
  before do
    @described_class_factory = described_class.name.underscore.to_sym
  end

  describe ".ride_coordinator_attributes" do
    it "knows which of its attributes are trip attributes" do
      expect(described_class.ride_coordinator_attributes).not_to include "id", "recurrence", "schedule_yaml", "created_at", "updated_at", "lock_version"
    end
  end
  
  describe ".generate!" do
    it "generates trips for all repeating trips" do
      scheduler = create @described_class_factory
      allow(described_class).to receive(:all).and_return([scheduler])
      expect(scheduler).to receive(:instantiate!)
      described_class.generate!
    end
  end
  
  describe "ScheduleAttributes module" do
    describe "#schedule_attributes" do
      before do
        @scheduler = build @described_class_factory
      end
    
      it "returns an openstruct" do
        expect(@scheduler.schedule_attributes).to be_a OpenStruct
      end
    end
  
    describe "#schedule_attributes=" do
      before do
        @scheduler = build @described_class_factory
      end
    
      it "populates the schedule_yaml field" do
        expect(@scheduler.schedule_yaml).to be_nil
        @scheduler.schedule_attributes = {}
        expect(@scheduler.schedule_yaml).not_to be_nil
      end
    end
  
    describe "#schedule" do
      before do
        @scheduler = build @described_class_factory
      end

      it "returns an IceCube::Schedule" do
        expect(@scheduler.schedule).to be_a IceCube::Schedule
      end
    end
  end
end
