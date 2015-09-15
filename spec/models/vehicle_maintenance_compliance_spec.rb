require 'rails_helper'

RSpec.describe VehicleMaintenanceCompliance, type: :model do
  it_behaves_like "an associable for a document" do
    before do
      @owner = create :vehicle
    end
  end
  
  it_behaves_like "a compliance event"
  
  it_behaves_like "a recurring compliance event" do
    before do
      @owner_class = RecurringVehicleMaintenanceCompliance

      # All model attributes that are note included in 
      # .editable_occurrence_attributes
      @unchangeable_attributes = [:event, :notes, :due_type, :due_date, :due_mileage]
      
      # Sample values for the attributes returned by 
      # .editable_occurrence_attributes
      @changeable_attributes = {compliance_date: Date.current, compliance_mileage: 123}
    end
  end

  it "requires a vehicle" do
    compliance = build :vehicle_maintenance_compliance, vehicle: nil
    expect(compliance.valid?).to be_falsey
    expect(compliance.errors.keys).to include :vehicle
  end

  it "requires a due_type of either 'date', 'mileage', or 'both'" do
    compliance = build :vehicle_maintenance_compliance, due_type: nil, due_date: Date.current, due_mileage: 1
    expect(compliance.valid?).to be_falsey
    expect(compliance.errors.keys).to include :due_type

    compliance.due_type = "foo"
    expect(compliance.valid?).to be_falsey
    expect(compliance.errors.keys).to include :due_type

    %w(date mileage both).each do |due_type|
      compliance.due_type = due_type
      expect(compliance.valid?).to be_truthy
    end
  end

  it "requires a compliance_date if compliance_mileage is present" do
    compliance = build :vehicle_maintenance_compliance, compliance_date: nil, compliance_mileage: 1234
    expect(compliance.valid?).to be_falsey
    expect(compliance.errors.keys).to include :compliance_date

    compliance.compliance_mileage = nil
    expect(compliance.valid?).to be_truthy
  end

  it "requires a compliance_mileage if compliance_date is present" do
    compliance = build :vehicle_maintenance_compliance, compliance_date: Date.current, compliance_mileage: nil
    expect(compliance.valid?).to be_falsey
    expect(compliance.errors.keys).to include :compliance_mileage

    compliance.compliance_date = nil
    expect(compliance.valid?).to be_truthy
  end
  
  describe "due_types" do
    describe "date" do
      before do
        @compliance = build :vehicle_maintenance_compliance, due_type: "date", due_date: Date.current, due_mileage: 1
      end

      it "requires a due_date" do
        @compliance.due_date = nil
        expect(@compliance.valid?).to be_falsey
        expect(@compliance.errors.keys).to include :due_date
      end

      it "does not require a due_mileage" do
        @compliance.due_mileage = nil
        expect(@compliance.valid?).to be_truthy
      end
    end

    describe "mileage" do
      before do
        @compliance = build :vehicle_maintenance_compliance, due_type: "mileage", due_date: Date.current, due_mileage: 1
      end

      it "does not require a due_date" do
        @compliance.due_date = nil
        expect(@compliance.valid?).to be_truthy
      end

      it "requires due_mileage to be an integer > 0" do
        @compliance.due_mileage = nil
        expect(@compliance.valid?).to be_falsey
        expect(@compliance.errors.keys).to include :due_mileage

        @compliance.due_mileage = 0
        expect(@compliance.valid?).to be_falsey
        expect(@compliance.errors.keys).to include :due_mileage

        @compliance.due_mileage = 1.2
        expect(@compliance.valid?).to be_falsey
        expect(@compliance.errors.keys).to include :due_mileage

        @compliance.due_mileage = 1
        expect(@compliance.valid?).to be_truthy
      end
    end

    describe "both" do
      before do
        @compliance = build :vehicle_maintenance_compliance, due_type: "both", due_date: Date.current, due_mileage: 1
      end

      it "requires a due_date" do
        @compliance.due_date = nil
        expect(@compliance.valid?).to be_falsey
        expect(@compliance.errors.keys).to include :due_date
      end

      it "requires due_mileage to be an integer > 0" do
        @compliance.due_mileage = nil
        expect(@compliance.valid?).to be_falsey
        expect(@compliance.errors.keys).to include :due_mileage

        @compliance.due_mileage = 0
        expect(@compliance.valid?).to be_falsey
        expect(@compliance.errors.keys).to include :due_mileage

        @compliance.due_mileage = 1.2
        expect(@compliance.valid?).to be_falsey
        expect(@compliance.errors.keys).to include :due_mileage

        @compliance.due_mileage = 1
        expect(@compliance.valid?).to be_truthy
      end
    end
  end

  describe ".for_vehicle" do
    before do
      @vehicle_1 = create :vehicle
      @vehicle_2 = create :vehicle
      @for_vehicle_1 = create :vehicle_maintenance_compliance, vehicle: @vehicle_1
      @for_vehicle_2 = create :vehicle_maintenance_compliance, vehicle: @vehicle_2
    end
    
    it "finds compliance events for a specified vehicle or vehicle id" do
      expect(VehicleMaintenanceCompliance.for_vehicle(@vehicle_1)).to include @for_vehicle_1
      expect(VehicleMaintenanceCompliance.for_vehicle(@vehicle_1)).not_to include @for_vehicle_2
    end

    it "can find compliance events for an array of vehicles or vehicle ids" do
      expect(VehicleMaintenanceCompliance.for_vehicle([@vehicle_1, @vehicle_2])).to include @for_vehicle_1
      expect(VehicleMaintenanceCompliance.for_vehicle([@vehicle_1, @vehicle_2])).to include @for_vehicle_2
    end
  end
  
  describe ".overdue" do
    before do
      # Allow invalid due_mileage values so that we can force overdue values
      allow_any_instance_of(VehicleMaintenanceCompliance).to receive(:valid?).and_return(true)

      # Overdue
      @compliance_1 = create :vehicle_maintenance_compliance, due_type: "date", due_date: Date.current.yesterday
      @compliance_2 = create :vehicle_maintenance_compliance, due_type: "mileage", due_mileage: -1
      @compliance_3 = create :vehicle_maintenance_compliance, due_type: "both", due_date: Date.current.yesterday, due_mileage: -1

      # Not Overdue
      @compliance_4 = create :vehicle_maintenance_compliance, due_type: "date", due_date: Date.current.tomorrow
      @compliance_5 = create :vehicle_maintenance_compliance, due_type: "mileage", due_mileage: 100
      @compliance_6 = create :vehicle_maintenance_compliance, due_type: "both", due_date: Date.current.yesterday, due_mileage: 100
      @compliance_7 = create :vehicle_maintenance_compliance, due_type: "both", due_date: Date.current.tomorrow, due_mileage: -1
    end

    it "uses the #overdue? method to select overdue objects" do
      overdue = VehicleMaintenanceCompliance.overdue
      expect(overdue).to include @compliance_1, @compliance_2, @compliance_3
      expect(overdue).not_to include @compliance_4, @compliance_5, @compliance_6, @compliance_7
    end

    it "can find overdue compliance events as of a specific date (but it won't affect mileage criteria)" do
      overdue = VehicleMaintenanceCompliance.overdue as_of: Date.current.yesterday
      expect(overdue).to include @compliance_2
      expect(overdue).not_to include @compliance_1, @compliance_3, @compliance_4, @compliance_5, @compliance_6, @compliance_7
    end
  end

  # RADAR Not currently used, but will be by reports
  describe ".due_soon" do
    before do
      # Due today, or within 500 miles
      @compliance_today             = create :vehicle_maintenance_compliance, event: "compliance_today", due_type: "date", due_date: Date.current
      @compliance_500_mi            = create :vehicle_maintenance_compliance, event: "compliance_500_mi", due_type: "mileage", due_mileage: 499
      @compliance_today_and_500_mi  = create :vehicle_maintenance_compliance, event: "compliance_today_and_500_mi", due_type: "both", due_date: Date.current, due_mileage: 499
      @compliance_today_and_750_mi  = create :vehicle_maintenance_compliance, event: "compliance_today_and_750_mi", due_type: "both", due_date: Date.current, due_mileage: 749
      @compliance_today_and_1000_mi = create :vehicle_maintenance_compliance, event: "compliance_today_and_1000_mi", due_type: "both", due_date: Date.current, due_mileage: 999

      # Due tomorrow, or within 750 miles
      @compliance_tomorrow             = create :vehicle_maintenance_compliance, event: "compliance_tomorrow", due_type: "date", due_date: Date.current.tomorrow
      @compliance_750_mi               = create :vehicle_maintenance_compliance, event: "compliance_750_mi", due_type: "mileage", due_mileage: 749
      @compliance_tomorrow_and_500_mi  = create :vehicle_maintenance_compliance, event: "compliance_tomorrow_and_500_mi", due_type: "both", due_date: Date.current.tomorrow, due_mileage: 499
      @compliance_tomorrow_and_750_mi  = create :vehicle_maintenance_compliance, event: "compliance_tomorrow_and_750_mi", due_type: "both", due_date: Date.current.tomorrow, due_mileage: 749
      @compliance_tomorrow_and_1000_mi = create :vehicle_maintenance_compliance, event: "compliance_tomorrow_and_1000_mi", due_type: "both", due_date: Date.current.tomorrow, due_mileage: 999

      # Due later, or within 1000 miles
      @compliance_7_days             = create :vehicle_maintenance_compliance, event: "compliance_7_days", due_type: "date", due_date: Date.current + 7.days
      @compliance_1000_mi            = create :vehicle_maintenance_compliance, event: "compliance_1000_mi", due_type: "mileage", due_mileage: 999
      @compliance_7_days_and_500_mi  = create :vehicle_maintenance_compliance, event: "compliance_7_days_and_500_mi", due_type: "both", due_date: Date.current + 7.days, due_mileage: 499
      @compliance_7_days_and_750_mi  = create :vehicle_maintenance_compliance, event: "compliance_7_days_and_750_mi", due_type: "both", due_date: Date.current + 7.days, due_mileage: 749
      @compliance_7_days_and_1000_mi = create :vehicle_maintenance_compliance, event: "compliance_7_days_and_1000_mi", due_type: "both", due_date: Date.current + 7.days, due_mileage: 999
    end

    it "finds items that are within 6 days of their due_date and/or within 500 miles of their due_milage, by default" do
      compliances = VehicleMaintenanceCompliance.due_soon

      expect(compliances).to include     @compliance_today,
                                         @compliance_500_mi,
                                         @compliance_today_and_500_mi,
                                         @compliance_tomorrow,
                                         @compliance_tomorrow_and_500_mi

      expect(compliances).to_not include @compliance_today_and_750_mi,
                                         @compliance_today_and_1000_mi,
                                         @compliance_750_mi,
                                         @compliance_tomorrow_and_750_mi,
                                         @compliance_tomorrow_and_1000_mi,
                                         @compliance_7_days,
                                         @compliance_1000_mi,
                                         @compliance_7_days_and_500_mi,
                                         @compliance_7_days_and_750_mi,
                                         @compliance_7_days_and_1000_mi
    end

    it "can find items due as of a specific date (with defaults: 6 days out, and/or within 500 miles of their due_milage)" do
      compliances = VehicleMaintenanceCompliance.due_soon(as_of: Date.current.tomorrow)

      expect(compliances).to include     @compliance_500_mi,
                                         @compliance_tomorrow,
                                         @compliance_tomorrow_and_500_mi,
                                         @compliance_7_days,
                                         @compliance_7_days_and_500_mi

      expect(compliances).to_not include @compliance_today,
                                         @compliance_today_and_500_mi,
                                         @compliance_today_and_750_mi,
                                         @compliance_today_and_1000_mi,
                                         @compliance_750_mi,
                                         @compliance_tomorrow_and_750_mi,
                                         @compliance_tomorrow_and_1000_mi,
                                         @compliance_1000_mi,
                                         @compliance_7_days_and_750_mi,
                                         @compliance_7_days_and_1000_mi
    end

    it "can find items due within a specific mileage (with due_date defaults: as of today and 6 days out)" do
      compliances = VehicleMaintenanceCompliance.due_soon(within_mileage: 750)

      expect(compliances).to include     @compliance_today,
                                         @compliance_500_mi,
                                         @compliance_today_and_500_mi,
                                         @compliance_today_and_750_mi,
                                         @compliance_tomorrow,
                                         @compliance_750_mi,
                                         @compliance_tomorrow_and_500_mi,
                                         @compliance_tomorrow_and_750_mi

      expect(compliances).to_not include @compliance_today_and_1000_mi,
                                         @compliance_tomorrow_and_1000_mi,
                                         @compliance_1000_mi,
                                         @compliance_7_days,
                                         @compliance_7_days_and_500_mi,
                                         @compliance_7_days_and_750_mi,
                                         @compliance_7_days_and_1000_mi
    end
  end

  describe "#vehicle_odometer_reading" do
    it "returns its vehicle's last_odometer_reading" do
      compliance = create :vehicle_maintenance_compliance
      expect(compliance.vehicle).to receive(:last_odometer_reading).and_return(123)
      expect(compliance.vehicle_odometer_reading).to eq 123
    end
  end

  describe "#overdue?" do
    describe "with due_type" do
      describe "date" do
        before do
          @compliance = create :vehicle_maintenance_compliance, due_type: "date", due_date: Date.current
        end

        it "checks if the due_date is after Date.current, by default" do
          expect(@compliance.overdue?).to be_falsey

          Timecop.freeze(Date.current.tomorrow) do
            expect(@compliance.overdue?).to be_truthy
          end
        end

        it "can optionally accept another date to check against the due_date" do
          expect(@compliance.overdue?(as_of: Date.current.yesterday)).to be_falsey
          expect(@compliance.overdue?(as_of: Date.current.tomorrow)).to be_truthy
        end

        it "can optionally accept a range of dates to check against the due_date" do
          expect(@compliance.overdue?(as_of: Date.current..Date.current.tomorrow)).to be_truthy
        end

        it "doesn't care about due_mileage" do
          expect(@compliance).not_to receive(:due_mileage)
          expect(@compliance.overdue?).to be_falsey
        end
      end

      describe "mileage" do
        before do
          @compliance = create :vehicle_maintenance_compliance, due_type: "mileage", due_mileage: 100
        end

        it "doesn't care about due_date" do
          expect(@compliance).not_to receive(:due_date)
          expect(@compliance.overdue?).to be_falsey
        end

        it "checks if the due_mileage is over the #vehicle_odometer_reading, by default" do
          expect(@compliance).to receive(:vehicle_odometer_reading).and_return(100)
          expect(@compliance.overdue?).to be_falsey

          expect(@compliance).to receive(:vehicle_odometer_reading).and_return(101)
          expect(@compliance.overdue?).to be_truthy
        end

        it "can optionally accept another mileage to check against the due_mileage" do
          expect(@compliance.overdue?(mileage: 100)).to be_falsey
          expect(@compliance.overdue?(mileage: 101)).to be_truthy
        end
        
        it "can optionally accept a range of mileages to check against the due_mileage" do
          expect(@compliance.overdue?(mileage: 100..101)).to be_truthy
        end
      end

      describe "both" do
        before do
          @compliance = create :vehicle_maintenance_compliance, due_type: "both", due_date: Date.current, due_mileage: 100
        end

        it "checks against both due_date and due_mileage" do
          expect(@compliance.overdue?).to be_falsey
          expect(@compliance.overdue?(as_of: Date.current.tomorrow)).to be_falsey
          expect(@compliance.overdue?(mileage: 101)).to be_falsey
          expect(@compliance.overdue?(as_of: Date.current.tomorrow, mileage: 101)).to be_truthy
        end
      end
    end
  end
end
