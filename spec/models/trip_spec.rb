require "rails_helper"

RSpec.describe Trip do
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

  describe "after validation for trips with repetition:" do
    attr_accessor :trip
    
    before do
      @trip = build(:trip,
        :repeats_mondays => true, 
        :repeats_tuesdays => false,
        :repeats_wednesdays => false,
        :repeats_thursdays => false,
        :repeats_fridays => false,
        :repeats_saturdays => false,
        :repeats_sundays => false,
        :repetition_vehicle_id => -1,
        :repetition_driver_id => 1,
        :repetition_interval => 1)
      expect(RepeatingTrip.count).to eq(0)
    end

    context "when creating a trip with repeating trip data" do
      it "should accept repeating trip values" do
        expect(trip.repeats_mondays).to eq(true)
        expect(trip.repeats_tuesdays).to eq(false)
        expect(trip.repeats_wednesdays).to eq(false)
        expect(trip.repeats_thursdays).to eq(false)
        expect(trip.repeats_fridays).to eq(false)
        expect(trip.repeats_saturdays).to eq(false)
        expect(trip.repeats_sundays).to eq(false)
        expect(trip.repetition_vehicle_id).to eq(-1)
        expect(trip.repetition_driver_id).to eq(1)
        expect(trip.repetition_interval).to eq(1)
      end

      it "should create a repeating trip when saved" do
        expect {
          trip.save
          expect(trip.repeating_trip).not_to be_nil
        }.to change(RepeatingTrip, :count).by(1)
        expect(trip.repeating_trip_id).not_to be_nil
      end

      it "should instantiate trips for three weeks out" do
        skip('failed: Need to double check with Chris')
        trip.save
        r_id = trip.repeating_trip_id
        # The trip we just created, which is next week, plus 2 more
        expect(Trip.where(:repeating_trip_id => r_id).count).to eq(3)
      end
    end

    context "when updating a future trip with repeating trip data," do
      before do
        trip.save
        trip.repeats_mondays = false
        trip.repeats_tuesdays = true
        trip.repetition_vehicle_id = 2
        trip.repetition_driver_id = 2
        trip.save
        trip.reload
      end

      it "should have the correct repeating trip attributes" do
        expect(trip.repeating_trip.schedule_attributes.monday).to be_nil
        expect(trip.repeating_trip.schedule_attributes.tuesday).to eq(1)
      end

      # TODO This test is failing on master. Uncomment after upgrade. Fix if
      # time allows.
      it "should have new child trips on the correct day" do
        pending('failed during rideconnection rails upgrade')
        count = 0
        Trip.where(:repeating_trip_id => trip.repeating_trip_id).where("id <> ?",trip.id).each do |t|
          count += 1 if t.pickup_time.strftime("%u") == "2"
        end
        count.should == 1
      end

      it "should have no child trips on the old day" do
        count = 0
        Trip.where(:repeating_trip_id => trip.repeating_trip_id).where("id <> ?",trip.id).each do |t|
          count += 1 if t.pickup_time.strftime("%u") == "1"
        end
        expect(count).to eq(0)
      end

      it "should tell me the correct repeating trip data when reloading the trip" do
        trip.reload
        expect(trip.repeats_mondays).to eq(false)
        expect(trip.repeats_tuesdays).to eq(true)
        expect(trip.repetition_vehicle_id).to eq(2)
        expect(trip.repetition_driver_id).to eq(2)
      end
    end
   
    context "when updating a past trip with repeating trip data," do
      before do
        trip.pickup_time = Time.now - 1.week
        trip.appointment_time = trip.pickup_time + 30.minutes
        trip.save
        trip.repeats_mondays = false
        trip.repeats_tuesdays = true
        trip.repetition_vehicle_id = 2
        trip.repetition_driver_id = 2
        trip.save
        trip.reload
      end

      it "should have the correct repeating trip attributes" do
        expect(trip.repeating_trip.schedule_attributes.monday).to be_nil
        expect(trip.repeating_trip.schedule_attributes.tuesday).to eq(1)
      end

      # TODO This test is failing on master. Uncomment after upgrade. Fix if
      # time allows.
      it "should have new child trips on the correct day" do
        pending('failed during rideconnection rails upgrade')
        count = 0
        Trip.where(:repeating_trip_id => trip.repeating_trip_id).where("id <> ?",trip.id).each do |t|
          count += 1 if t.pickup_time.strftime("%u") == "2"
        end
        count.should == 2
      end

      it "should have no child trips on the old day" do
        count = 0
        Trip.where(:repeating_trip_id => trip.repeating_trip_id).where("id <> ?",trip.id).each do |t|
          count += 1 if t.pickup_time.strftime("%u") == "1"
        end
        expect(count).to eq(0)
      end

      it "should tell me the correct repeating trip data when reloading the trip" do
        trip.reload
        expect(trip.repeats_mondays).to eq(false)
        expect(trip.repeats_tuesdays).to eq(true)
        expect(trip.repetition_vehicle_id).to eq(2)
        expect(trip.repetition_driver_id).to eq(2)
      end
    end

    context "when I clear out the repetition data" do
      before do
        trip.save
        trip.repeats_mondays = false
        @repeating_trip_id = trip.repeating_trip_id
        trip.save
      end

      it "should remove all future trips after the trip and delete the repeating trip record" do 
        expect(Trip.where(:repeating_trip_id => @repeating_trip_id).count).to eq(0)
        expect(RepeatingTrip.find_by_id(@repeating_trip_id)).to be_nil
      end
    end
  end
end
