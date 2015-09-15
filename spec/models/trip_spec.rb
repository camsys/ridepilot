require "rails_helper"

RSpec.describe Trip do
  it_behaves_like "a recurring ride coordinator" do
    before do
      # These options reflect the concern setup method:
      # schedules_occurrences_with :repeating_trip
      @occurrence_scheduler_association = :repeating_trip
      
      # To help us know what attribute to check occurrence dates against
      @occurrence_date_attribute = :pickup_time
    end
  end
  
  it "requires pickup_time to be a valid date" do
    trip = build :trip, pickup_time: "13/13/13", appointment_time: "12/12/12"
    expect(trip.valid?).to be_falsey
    expect(trip.errors.keys).to include :pickup_time
  
    trip.pickup_time = "12/12/12"
    expect(trip.valid?).to be_truthy
  end
  
  it "requires appointment_time to be a valid date" do
    trip = build :trip, appointment_time: "13/13/13"
    expect(trip.valid?).to be_falsey
    expect(trip.errors.keys).to include :appointment_time
  
    trip.appointment_time = "12/12/12"
    expect(trip.valid?).to be_truthy
  end

  it "if pickup_time is assigned a string that ends in 'a', it automatically appends an 'm' before parsing" do
    trip = build :trip
    time = "1976-05-09 01:00:00 a"
    trip.pickup_time = time
    expect(trip.pickup_time).not_to eq Time.zone.parse(time)
    expect(trip.pickup_time).to eq Time.zone.parse("#{time}m")
  end

  it "if appointment_time is assigned a string that ends in 'a', it automatically appends an 'm' before parsing" do
    trip = build :trip
    time = "1976-05-09 01:00:00 a"
    trip.appointment_time = time
    expect(trip.appointment_time).not_to eq Time.zone.parse(time)
    expect(trip.appointment_time).to eq Time.zone.parse("#{time}m")
  end

  describe "#repetition_customer_informed=" do
    before do
      @trip = build :trip
    end

    it "sets the @repetition_customer_informed instance variable" do
      expect(@trip.instance_variable_get("@repetition_customer_informed")).to be_nil
      @trip.repetition_customer_informed = true
      expect(@trip.instance_variable_get("@repetition_customer_informed")).to eq true
    end

    it "converts '1' and truthy values to true" do
      @trip.repetition_customer_informed = "1"
      expect(@trip.instance_variable_get("@repetition_customer_informed")).to eq true

      @trip.repetition_customer_informed = true
      expect(@trip.instance_variable_get("@repetition_customer_informed")).to eq true
    end
  
    it "converts other values to false" do
      @trip.repetition_customer_informed = "0"
      expect(@trip.instance_variable_get("@repetition_customer_informed")).to eq false

      @trip.repetition_customer_informed = "false"
      expect(@trip.instance_variable_get("@repetition_customer_informed")).to eq false

      @trip.repetition_customer_informed = false
      expect(@trip.instance_variable_get("@repetition_customer_informed")).to eq false
    end
  end

  describe "#repetition_customer_informed" do
    before do
      @trip = build :trip
    end

    it "returns the @repetition_customer_informed instance variable if it's present" do
      @trip.instance_variable_set "@repetition_customer_informed", true
      expect(@trip.repetition_customer_informed).to eq true
    end
  
    it "returns the scheduler's customer_informed if @repetition_customer_informed is nil and the scheduler is present" do
      @trip.repeating_trip = create :repeating_trip, customer_informed: true
      expect(@trip.repetition_customer_informed).to eq true
    end

    # TODO make repeating_trip including-class agnostic
    it "sets the @repetition_customer_informed instance variable if it is nil and the repeating_trip is present" do
      @trip.repeating_trip = create :repeating_trip, customer_informed: true
      expect(@trip.repetition_customer_informed).to eq true
      expect(@trip.instance_variable_get("@repetition_customer_informed")).to eq true
    end
  end

  describe "mileage" do
    it "should be an integer" do
      t = Trip.new
      expect(t).to respond_to(:mileage)
      t.mileage = "1"
      expect(t.mileage).to eq 1
      t.mileage = "0"
      expect(t.mileage).to eq 0
    end
    
    it "should only allow integers greater than 0" do
      t = Trip.new
      t.mileage = 0
      t.valid?
      expect(t.errors.keys.include?(:mileage)).to be_truthy
      expect(t.errors[:mileage]).to include "must be greater than 0"
      
      t.mileage = 1
      t.valid?
      expect(t.errors.keys.include?(:mileage)).not_to be_truthy
    end
  end

  describe "service_level" do
    it "should be an integer field" do
      t = Trip.new
      expect(t).to respond_to(:service_level_id)
      t.service_level_id = "1"
      expect(t.service_level_id).to eq(1)
      t.service_level_id = "0"
      expect(t.service_level_id).to eq(0)
    end
  end

  describe "medicaid_eligible" do
    it "should be a boolean field" do
      t = Trip.new
      expect(t).to respond_to(:medicaid_eligible)
      t.medicaid_eligible = "1"
      expect(t.medicaid_eligible).to be_truthy
      t.medicaid_eligible = "0"
      expect(t.medicaid_eligible).to be_falsey
    end
  end

  describe "before validation" do
    context "when there are no runs yet" do
      before do
        expect(Run.count).to eq(0)
      end
      
      it "does not create an associated run" do
        expect {
          trip = create :trip
          expect(trip.run).to be_nil
        }.not_to change(Run, :count)
      end
    end
  end

  describe "vehicle open seating capacity validation" do
    before do
      @start_time = Time.zone.parse("14:30")
      @end_time   = Time.zone.parse("15:30")
      
      @vehicle = create :vehicle, seating_capacity: 1
      @run = create :run, vehicle: @vehicle
      @trip = build :trip, run: @run, pickup_time: @start_time, appointment_time: @end_time
    end
    
    it "ignores the validation if no run is present" do
      @trip.run = nil
      expect(@trip.valid?).to be_truthy
    end
    
    it "is valid if there is available seating capacity" do
      expect(@trip.valid?).to be_truthy
    end
    
    it "is not valid if there is not enough seating capacity to accommodate the full size of the trip" do
      @trip.guest_count = 1
      expect(@trip.valid?).to be_falsey
      expect(@trip.errors.keys).to include :base

      @trip.guest_count = 0
      expect(@trip.valid?).to be_truthy
    end
    
    it "doesn't include it's past seat occupancy when checking open capacity on updates" do
      @trip.save!
      expect(@trip.valid?).to be_truthy
    end
    
    it "is not valid if the seating capacity increases on update beyond what's available" do
      @trip.save!
      @trip.guest_count = 1
      expect(@trip.valid?).to be_falsey
      expect(@trip.errors.keys).to include :base

      @trip.guest_count = 0
      expect(@trip.valid?).to be_truthy
    end
  end
  
  describe "#trip_size" do
    before do
      @trip = build :trip
    end
    
    it "assumes a minimum size of 1" do
      expect(@trip.trip_size).to eq 1
    end

    it "accounts for guests and attendants" do
      @trip.guest_count = 1
      @trip.attendant_count = 1
      expect(@trip.trip_size).to eq 3
    end

    it "accounts for groups" do
      @trip.customer = create :customer, group: true
      @trip.group_size = 4
      expect(@trip.trip_size).to eq 4
    end
  end

  describe ".incomplete" do
    it "returns trips without any trip_result" do
      incomplete_1 = create :trip
      incomplete_2 = create :trip
      complete     = create :trip, :complete
      turned_down  = create :trip, :turned_down
      miscelaneous = create :trip, trip_result: create(:trip_result)
      
      incompletes = Trip.incomplete
      expect(incompletes).to include incomplete_1, incomplete_2
      expect(incompletes).not_to include complete, turned_down, miscelaneous
    end
  end

  describe ".during" do
    before do
      @start_time = Time.zone.parse("14:30")
      @end_time   = Time.zone.parse("15:30")
      
      @starts_and_ends_before_start        = create :trip, pickup_time: @start_time - 15.minutes, appointment_time: @start_time
      @starts_before_start_ends_before_end = create :trip, pickup_time: @start_time - 15.minutes, appointment_time: @end_time
      @starts_after_start_ends_after_end   = create :trip, pickup_time: @start_time,              appointment_time: @end_time + 15.minutes
      @starts_after_start_ends_before_end  = create :trip, pickup_time: @start_time,              appointment_time: @end_time
      @starts_and_ends_after_end           = create :trip, pickup_time: @end_time,                appointment_time: @end_time + 15.minutes
      @starts_before_start_ends_after_end  = create :trip, pickup_time: @start_time - 15.minutes, appointment_time: @end_time + 15.minutes
      
      @during = Trip.during(@start_time, @end_time)
    end
    
    it "returns trips that are occurring in the same time frame" do
      expect(@during).to include @starts_before_start_ends_before_end, 
                                 @starts_after_start_ends_after_end, 
                                 @starts_after_start_ends_before_end, 
                                 @starts_before_start_ends_after_end
    end

    it "ignores trips that start and end before the time frame" do
      expect(@during).not_to include @starts_and_ends_before_start
    end
    
    it "ignores trips that start and end after the time frame" do
      expect(@during).not_to include @starts_and_ends_after_end
    end
  end
  
  describe ".by_funding_source" do
    before do
      @funding_source_1 = create :funding_source, name: "Foo"
      @funding_source_2 = create :funding_source, name: "Bar"
      
      @trip_1 = create :trip, funding_source: @funding_source_1
      @trip_2 = create :trip, funding_source: @funding_source_2
    end
    
    it "finds trips by funding source by name" do
      expect(Trip.by_funding_source("Foo")).to include @trip_1
      expect(Trip.by_funding_source("Foo")).not_to include @trip_2
      expect(Trip.by_funding_source("Bar")).to include @trip_2
      expect(Trip.by_funding_source("Bar")).not_to include @trip_1
    end
  end
  
  describe ".by_trip_purpose" do
    before do
      @trip_purpose_1 = create :trip_purpose, name: "Foo"
      @trip_purpose_2 = create :trip_purpose, name: "Bar"
      
      @trip_1 = create :trip, trip_purpose: @trip_purpose_1
      @trip_2 = create :trip, trip_purpose: @trip_purpose_2
    end
    
    it "finds trips by trip purpose by name" do
      expect(Trip.by_trip_purpose("Foo")).to include @trip_1
      expect(Trip.by_trip_purpose("Foo")).not_to include @trip_2
      expect(Trip.by_trip_purpose("Bar")).to include @trip_2
      expect(Trip.by_trip_purpose("Bar")).not_to include @trip_1
    end
  end

  # TODO complete these backfilled examples
  describe "incomplete examples" do
    describe "#date" do
      it "returns a date based on pickup_time"
    end

    describe "#complete" do
      it "checks whether the trip_result code is 'COMP'"
    end
  
    describe "#pending" do
      it "checks whether the trip_result is blank"
    end
  
    describe "#vehicle_id" do
      it "returns the run vehicle_id if a run is present, or the @vehicle_id instance variable"
    end
  
    describe "#driver_id" do
      it "returns the @driver_id instance variable if present, or the run driver_id if the run is present, or nil"
    end
  
    describe "#run_text" do
      it "returns 'Cab' if it's a cab trip"
      it "returns the run label if it's not a cab trip and a run is present"
      it "returns '(No run specified)' if it's not a cab and no run is present"
    end
  
    describe "#trip_count" do
      it "returns #trip_size if it's not round_trip"
      it "returns #trip_size * 2 if it's round_trip"
    end
  
    describe "#is_in_district?" do
      it "checks whether the pickup_address and the dropoff_address are both considered in_district?"
    end

    describe "#allow_addressless_trip?" do
      it "checks whether the pickup_address and the dropoff_address are both considered in_district?"
    end

    describe "#adjusted_run_id" do
      it "returns Run::CAB_RUN_ID if it's a cab trip"
      it "returns the run_id if it's not a cab trip and a run is present"
      it "returns Run::UNSCHEDULED_RUN_ID if it's not a cab trip and a run is not present"
    end
  
    describe "#as_calendar_json" do
      it "returns a hash"
    end

    describe "#as_run_event_json" do
      it "returns a hash"
    end
  end
end
