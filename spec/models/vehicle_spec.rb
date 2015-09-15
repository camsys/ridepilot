require "rails_helper"

RSpec.describe Vehicle, type: :model do
  it "requires a provider" do
    vehicle = build :vehicle, provider: nil
    expect(vehicle.valid?).to be_falsey
    expect(vehicle.errors.keys).to include :provider
  end
  
  it "requires a default_driver" do
    vehicle = build :vehicle, default_driver: nil
    expect(vehicle.valid?).to be_falsey
    expect(vehicle.errors.keys).to include :default_driver
  end
  
  it "requires a name" do
    vehicle = build :vehicle, name: nil
    expect(vehicle.valid?).to be_falsey
    expect(vehicle.errors.keys).to include :name
  end
  
  it "requires a properly formatted VIN, when present" do
    vehicle = build :vehicle, vin: nil
    expect(vehicle.valid?).to be_truthy
    
    # length: {is: 17}, format: {with: /\A[^ioq]*\z/i}    
    %w(x2345678901234567 y2345678901234567 z2345678901234567).each do |good_vin|
      vehicle.vin = good_vin
      expect(vehicle.valid?).to be_truthy
    end
    
    %w(z234567890123456 i2345678901234567 o2345678901234567 q2345678901234567).each do |bad_vin|
      vehicle.vin = bad_vin
      expect(vehicle.valid?).to be_falsey
      expect(vehicle.errors.keys).to include :vin
    end
  end

  it "requires registration_expiration_date to be a real date, when specified" do
    vehicle = build :vehicle, registration_expiration_date: nil
    expect(vehicle.valid?).to be_truthy

    vehicle.registration_expiration_date = "13/13/13"
    expect(vehicle.valid?).to be_falsey
    expect(vehicle.errors.keys).to include :registration_expiration_date

    vehicle.registration_expiration_date = "12/12/12"
    expect(vehicle.valid?).to be_truthy
  end

  it "requires seating_capacity to be an integer > 0" do
    vehicle = build :vehicle, seating_capacity: nil
    expect(vehicle.valid?).to be_falsey
    expect(vehicle.errors.keys).to include :seating_capacity

    vehicle.seating_capacity = 0
    expect(vehicle.valid?).to be_falsey
    expect(vehicle.errors.keys).to include :seating_capacity

    vehicle.seating_capacity = 1.2
    expect(vehicle.valid?).to be_falsey
    expect(vehicle.errors.keys).to include :seating_capacity

    vehicle.seating_capacity = 1
    expect(vehicle.valid?).to be_truthy
  end

  it "requires an ownership of either 'agency' or 'volunteer', or blank" do
    vehicle = build :vehicle, ownership: nil
    expect(vehicle.valid?).to be_truthy

    vehicle.ownership = "foo"
    expect(vehicle.valid?).to be_falsey
    expect(vehicle.errors.keys).to include :ownership

    %w(agency volunteer).each do |ownership|
      vehicle.ownership = ownership
      expect(vehicle.valid?).to be_truthy
    end
  end
  
  describe "#last_odometer_reading" do
    before do
      @vehicle = create :vehicle
    end
    
    it "knows the last run's odometer reading" do
      run_1 = create :run, vehicle: @vehicle, end_odometer: 123
      run_2 = create :run, vehicle: @vehicle, end_odometer: 456
      run_3 = create :run, vehicle: @vehicle
      expect(@vehicle.last_odometer_reading).to eq 456
    end
    
    it "fails gracefully when no runs are present" do
      expect(@vehicle.last_odometer_reading).to eq 0
    end
    
    it "fails gracefully when no runs have an end_odometer value" do
      run_1 = create :run, vehicle: @vehicle
      run_2 = create :run, vehicle: @vehicle
      run_3 = create :run, vehicle: @vehicle
      expect(@vehicle.last_odometer_reading).to eq 0
    end
  end

  describe "compliant?" do
    before do
      @vehicle = create :vehicle
    end

    it "returns true when a vehicle has no compliance entries" do
      expect(@vehicle.compliant?).to be_truthy
    end

    it "returns true when a vehicle's compliance entries are all complete" do
      create :vehicle_maintenance_compliance, :complete, vehicle: @vehicle
      expect(@vehicle.compliant?).to be_truthy
    end

    it "returns true when a vehicle's incomplete compliance entries are all not due" do
      create :vehicle_maintenance_compliance, vehicle: @vehicle, due_type: 'date', due_date: Date.current.tomorrow
      create :vehicle_maintenance_compliance, vehicle: @vehicle, due_type: 'mileage', due_mileage: 100
      create :vehicle_maintenance_compliance, vehicle: @vehicle, due_type: 'both', due_date: Date.current.tomorrow, due_mileage: 100
      expect(@vehicle.compliant?).to be_truthy
    end
    
    it "returns false when a vehicle has over due compliance entries" do
      allow(@vehicle).to receive(:last_odometer_reading).and_return(101)

      compliance = create :vehicle_maintenance_compliance, vehicle: @vehicle, due_type: 'date', due_date: Date.current.yesterday, due_mileage: 100
      expect(@vehicle.compliant?).to be_falsey

      compliance.update_attributes due_type: 'mileage'
      expect(@vehicle.reload.compliant?).to be_falsey

      compliance.update_attributes due_type: 'both'
      expect(@vehicle.reload.compliant?).to be_falsey
    end
  end
  
  describe "expired?" do
    before do
      @vehicle = create :vehicle
    end

    it "returns false when a vehicle has no warranty entries" do
      expect(@vehicle.expired?).to be_falsey
    end

    it "returns false when a vehicle's warranty entries all expire in the future" do
      create :vehicle_warranty, vehicle: @vehicle, expiration_date: Date.current.tomorrow
      expect(@vehicle.expired?).to be_falsey
    end
    
    it "returns true when a vehicle has expired warranty entries" do
      create :vehicle_warranty, vehicle: @vehicle, expiration_date: Date.current.yesterday
      expect(@vehicle.expired?).to be_truthy
    end
  end
  
  describe "documents" do
    before do
      @vehicle = create :vehicle
    end

    it "destroys documents when the vehicle is destroyed" do
      3.times { create :document, documentable: @vehicle }
      expect {
        @vehicle.destroy
      }.to change(Document, :count).by(-3)
    end
  end
  
  describe "tracking seating capacity" do
    before do
      @vehicle = create :vehicle, seating_capacity: 8
      @run = create :run, vehicle: @vehicle

      @start_time = Time.zone.parse("14:30")
      @end_time   = Time.zone.parse("15:30")
      
      @starts_before_start_ends_before_end = create :trip, run: @run, pickup_time: @start_time - 15.minutes, appointment_time: @end_time
      @starts_after_start_ends_after_end   = create :trip, run: @run, pickup_time: @start_time,              appointment_time: @end_time + 15.minutes
      @starts_after_start_ends_before_end  = create :trip, run: @run, pickup_time: @start_time,              appointment_time: @end_time
      @starts_before_start_ends_after_end  = create :trip, run: @run, pickup_time: @start_time - 15.minutes, appointment_time: @end_time + 15.minutes
    end
    
    it "returns the maximum seating_capacity when no qualifying trips are present" do
      Trip.destroy_all
      expect(@vehicle.open_seating_capacity @start_time, @end_time).to eq 8
    end
    
    it "assumes a minimum or 1 passenger per qualifying trip" do
      expect(@vehicle.open_seating_capacity @start_time, @end_time).to eq 4
    end

    it "accounts for trip guests and attendants" do
      @starts_before_start_ends_before_end.update_attributes guest_count: 1, attendant_count: 1
      expect(@vehicle.open_seating_capacity @start_time, @end_time).to eq 2
    end

    it "doesn't care about trips that start and end before the start_time" do
      create :trip, run: @run, pickup_time: @start_time - 15.minutes, appointment_time: @start_time
      expect(@vehicle.open_seating_capacity @start_time, @end_time).to eq 4
    end

    it "doesn't care about trips that start and end after the end_time" do
      create :trip, run: @run, pickup_time: @end_time, appointment_time: @end_time + 15.minutes
      expect(@vehicle.open_seating_capacity @start_time, @end_time).to eq 4
    end

    it "doesn't care about trips for other vehicles" do
      create :trip, pickup_time: @start_time, appointment_time: @end_time
      expect(@vehicle.open_seating_capacity @start_time, @end_time).to eq 4
    end
    
    it "can accept an optional trip or set of trips to ignore" do
      expect(@vehicle.open_seating_capacity @start_time, @end_time, ignore: @starts_before_start_ends_before_end).to eq 5
    end
  end
end
