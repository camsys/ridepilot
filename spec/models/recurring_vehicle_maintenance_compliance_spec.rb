require 'rails_helper'

RSpec.describe RecurringVehicleMaintenanceCompliance, type: :model do
  it_behaves_like "a recurring compliance event scheduler" do
    before do
      # These options reflect the concern setup method:
      # creates_occurrences_for :vehicle_maintenance_compliances, on: :vehicles
      @occurrence_association = :vehicle_maintenance_compliances
      @occurrence_owner_association = :vehicles      
      @complete_with = Proc.new do |compliance|
        compliance.update_attributes compliance_date: Date.current, compliance_mileage: 123
      end
    end
  end
  
  # This field is specific to RecurringVehicleMaintenanceCompliance
  it "requires a recurrence_type of either 'date', 'mileage', or 'both'" do
    recurrence = build :recurring_vehicle_maintenance_compliance, recurrence_type: nil, recurrence_mileage: 1
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :recurrence_type

    recurrence.recurrence_type = "foo"
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :recurrence_type

    %w(date mileage both).each do |recurrence_type|
      recurrence.recurrence_type = recurrence_type
      expect(recurrence.valid?).to be_truthy
    end
  end

  # The "a recurring compliance event scheduler" shared examples already test
  # appropriate values. We're just testing that the value is reuired under
  # certain conditions
  it "requires a recurrence_schedule when recurrence type is 'date' or 'both'" do
    recurrence = build :recurring_vehicle_maintenance_compliance, recurrence_type: "date", recurrence_schedule: nil, recurrence_mileage: 1
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :recurrence_schedule

    recurrence.recurrence_type = "both"
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :recurrence_schedule

    recurrence.recurrence_type = "mileage"
    expect(recurrence.valid?).to be_truthy
  end

  # The "a recurring compliance event scheduler" shared examples already test
  # appropriate values. We're just testing that the value is reuired under
  # certain conditions
  it "requires a recurrence_frequency when recurrence type is 'date' or 'both'" do
    recurrence = build :recurring_vehicle_maintenance_compliance, recurrence_type: "date", recurrence_frequency: nil, recurrence_mileage: 1
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :recurrence_frequency

    recurrence.recurrence_type = "both"
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :recurrence_frequency

    recurrence.recurrence_type = "mileage"
    expect(recurrence.valid?).to be_truthy
  end
  
  # This field is specific to RecurringVehicleMaintenanceCompliance
  it "requires a recurrence_mileage when recurrence type is 'mileage' or 'both'" do
    recurrence = build :recurring_vehicle_maintenance_compliance, recurrence_type: "mileage", recurrence_mileage: nil
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :recurrence_mileage

    recurrence.recurrence_type = "both"
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :recurrence_mileage

    recurrence.recurrence_type = "date"
    expect(recurrence.valid?).to be_truthy
  end

  # This field is specific to RecurringVehicleMaintenanceCompliance
  it "requires recurrence_mileage to be an integer greater than 0 when its presence is required" do
    recurrence = build :recurring_vehicle_maintenance_compliance, recurrence_type: "mileage", recurrence_mileage: nil
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :recurrence_mileage

    recurrence.recurrence_mileage = 0
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :recurrence_mileage

    recurrence.recurrence_mileage = 1.2
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :recurrence_mileage

    recurrence.recurrence_mileage = 1
    expect(recurrence.valid?).to be_truthy
  end
  
  # The "a recurring compliance event scheduler" shared examples already test
  # appropriate values. We're just testing that the value is reuired under
  # certain conditions
  it "requires a start_date when recurrence type is 'date' or 'both'" do
    recurrence = build :recurring_vehicle_maintenance_compliance, start_date: nil, recurrence_type: "date", recurrence_mileage: 1
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :start_date

    recurrence.recurrence_type = "both"
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :start_date

    recurrence.recurrence_type = "mileage"
    expect(recurrence.valid?).to be_truthy
  end
  
  # This validation is specific to RecurringVehicleMaintenanceCompliance
  it "does not allow a future_start_rule of 'time_span' when the recurrence_type is 'mileage'" do
    recurrence = build :recurring_vehicle_maintenance_compliance, recurrence_type: "mileage", recurrence_mileage: 1, future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 1
    expect(recurrence.valid?).to be_falsey
    expect(recurrence.errors.keys).to include :future_start_rule

    recurrence.recurrence_type = "date"
    expect(recurrence.valid?).to be_truthy

    recurrence.recurrence_type = "both"
    expect(recurrence.valid?).to be_truthy
  end

  # The "a recurring compliance event scheduler" shared examples already test
  # occurrence generation for date based scheduling. The specs below exercise
  # functionality specific to RecurringVehicleMaintenanceCompliance, 
  # specifically when the recurrence_type is 'mileage' or 'both'

  describe ".occurrence_mileages_on_schedule_in_range" do
    before do
      @recurrence = create :recurring_vehicle_maintenance_compliance,
        recurrence_type: "mileage",
        recurrence_mileage: 500
    end

    it "uses 0 to calculate the first occurrence by default" do
      expect(RecurringVehicleMaintenanceCompliance.occurrence_mileages_on_schedule_in_range(@recurrence).first).to eq 0
    end

    it "accepts an optional first_mileage to calculate the first occurrence" do
      expect(RecurringVehicleMaintenanceCompliance.occurrence_mileages_on_schedule_in_range(@recurrence, first_mileage: 1).first).to eq 1
    end

    it "calculates mileages within a 6000 miles window by default" do
      expect(RecurringVehicleMaintenanceCompliance.occurrence_mileages_on_schedule_in_range(@recurrence).last).to eq 6000
    end

    it "can accept an optional range_start_mileage" do
      expect(RecurringVehicleMaintenanceCompliance.occurrence_mileages_on_schedule_in_range(@recurrence, range_start_mileage: 1000).first).to eq 1000
    end

    it "can accept an optional range_end_mileage" do
      expect(RecurringVehicleMaintenanceCompliance.occurrence_mileages_on_schedule_in_range(@recurrence, range_end_mileage: 1000).last).to eq 1000
    end

    it "setting a range_start_mileage influences the default range_end_mileage" do
      expect(RecurringVehicleMaintenanceCompliance.occurrence_mileages_on_schedule_in_range(@recurrence, range_start_mileage: 500).last).to eq 6500
    end
  end

  describe ".next_occurrence_mileage_from_previous_mileage_in_range" do
    before do
      @recurrence = create :recurring_vehicle_maintenance_compliance,
        recurrence_type: "mileage",
        recurrence_mileage: 500
    end

    it "returns the next occurrence mileage from previous_mileage" do
      expect(RecurringVehicleMaintenanceCompliance.next_occurrence_mileage_from_previous_mileage_in_range @recurrence, 0).to eq 500
    end

    it "calculates mileages within a 6000 mile window by default" do
      @recurrence.update_columns recurrence_mileage: 7000
      expect(RecurringVehicleMaintenanceCompliance.next_occurrence_mileage_from_previous_mileage_in_range @recurrence, 0).to be_nil
    end

    it "can accept an optional range_end_mileage" do
      @recurrence.update_columns recurrence_mileage: 7000
      expect(RecurringVehicleMaintenanceCompliance.next_occurrence_mileage_from_previous_mileage_in_range @recurrence, 0, range_end_mileage: 7000).to eq 7000
    end
  end

  # Unlike date based schedules, mileage based schedules should always be
  # on schedule (i.e. multiples of the recurrence_mileage)
  describe ".adjusted_start_mileage" do
    before do
      @recurrence = create :recurring_vehicle_maintenance_compliance, recurrence_mileage: 500
    end

    describe "when as_of is less than or equal to the recurrence_mileage" do
      describe "with a future_start_rule of 'immediately'" do
        it "should return the recurrence_mileage" do
          expect(RecurringVehicleMaintenanceCompliance.adjusted_start_mileage @recurrence).to eq 500
        end
      end

      describe "with a future_start_rule of 'on_schedule'" do
        before do
          @recurrence.update_columns future_start_rule: "on_schedule"
        end

        it "should return the recurrence_mileage" do
          expect(RecurringVehicleMaintenanceCompliance.adjusted_start_mileage @recurrence).to eq 500
        end
      end

      describe "with a future_start_rule of 'time_span'" do
        before do
          @recurrence.update_columns future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 1
        end

        it "should return the recurrence_mileage" do
          expect(RecurringVehicleMaintenanceCompliance.adjusted_start_mileage @recurrence).to eq 500
        end
      end
    end

    describe "when as_of is after the recurrence start_mileage" do
      describe "with a future_start_rule of 'immediately'" do
        it "should return the next mileage of the occurrence on or after as_of, according to the recurrence schedule" do
          expect(RecurringVehicleMaintenanceCompliance.adjusted_start_mileage @recurrence, as_of: 750).to eq 1000
        end
      end

      describe "with a future_start_rule of 'on_schedule'" do
        before do
          @recurrence.update_columns future_start_rule: "on_schedule"
        end

        it "should return the next mileage of the occurrence on or after as_of, according to the recurrence schedule" do
          expect(RecurringVehicleMaintenanceCompliance.adjusted_start_mileage @recurrence, as_of: 750).to eq 1000
        end
      end

      describe "with a future_start_rule of 'time_span'" do
        before do
          @recurrence.update_columns recurrence_type: "both", future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 1
        end

        it "should return the next mileage of the occurrence on or after as_of, according to the recurrence schedule" do
          expect(RecurringVehicleMaintenanceCompliance.adjusted_start_mileage @recurrence, as_of: 750).to eq 1000
        end
      end
    end
  end

  describe ".generate!" do
    it "invokes our custom generator" do
      create :recurring_vehicle_maintenance_compliance
      expect(RecurringVehicleMaintenanceCompliance).to receive :custom_vehicle_maintenance_compliance_generator
      RecurringVehicleMaintenanceCompliance.generate!
    end
  
    describe "when the recurrence_type is 'date'" do
      it "calls the .default_generator method" do
        create :recurring_vehicle_maintenance_compliance
        expect(RecurringVehicleMaintenanceCompliance).to receive :default_generator
        RecurringVehicleMaintenanceCompliance.generate!
      end
    end

    describe "when the recurrence_type is 'mileage'" do
      before do
        @recurrence = create :recurring_vehicle_maintenance_compliance,
          recurrence_type: "mileage", 
          recurrence_mileage: 500,
          future_start_rule: "immediately",
          compliance_based_scheduling: false
        
        @provider = @recurrence.provider
      end
      
      describe "when frequency based scheduling is preferred" do
        before do
          @vehicle = create :vehicle, provider: @provider
        end

        describe "without prior event occurrences" do
          it "schedules new events on a schedule based on the recurrence_mileage and the vehicle's last_odometer_reading, up to 6000 miles out" do              
            # A vehicle's last_odometer_reading is 0 by default
            expected_mileages = [
              500, 1000, 1500, 
              2000, 2500, 3000, 
              3500, 4000, 4500, 
              5000, 5500, 6000
            ]

            expect {
              RecurringVehicleMaintenanceCompliance.generate!
            }.to change(VehicleMaintenanceCompliance, :count).by(12)

            expected_mileages.each do |expected_mileage|
              expect(@vehicle.vehicle_maintenance_compliances.where(due_mileage: expected_mileage)).to exist
            end
          end

          it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
            allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)
            
            expected_mileages = [
              1500, 2000, 2500,
              3000, 3500, 4000,
              4500, 5000, 5500,
              6000, 6500, 7000
            ]

            expect {
              RecurringVehicleMaintenanceCompliance.generate!
            }.to change(VehicleMaintenanceCompliance, :count).by(12)

            expected_mileages.each do |expected_mileage|
              expect(@vehicle.vehicle_maintenance_compliances.where(due_mileage: expected_mileage)).to exist
            end
          end

          it "won't schedule anything when the recurrence_mileage is more than 6000 over the vehicle's last_odometer_reading" do
            # A vehicle's last_odometer_reading is 0 by default
            @recurrence.update_attributes recurrence_mileage: 7000
            
            expect {
              RecurringVehicleMaintenanceCompliance.generate!
            }.not_to change(VehicleMaintenanceCompliance, :count)
          end

          it "will only schedule one event when the recurrence_mileage means the second occurrence will fall outside of 6000 miles from the vehicle's last_odometer_reading" do
            # A vehicle's last_odometer_reading is 0 by default
            @recurrence.update_attributes recurrence_mileage: 3001
            
            expect {
              RecurringVehicleMaintenanceCompliance.generate!
            }.to change(VehicleMaintenanceCompliance, :count).by(1)
          end
        end

        describe "with prior event occurrences" do
          before do
            # Creates 12 500-mile occurrences due from 500 to 6000 miles
            RecurringVehicleMaintenanceCompliance.generate!
          end

          it "won't schedule anything if the vehicle's last_odometer_reading hasn't increased by more than the recurrence_mileage since the last time events were generated" do
            allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(499)

            expect {
              RecurringVehicleMaintenanceCompliance.generate!
            }.not_to change(VehicleMaintenanceCompliance, :count)
          end

          it "schedules new events on a schedule based on the vehicle's last_odometer_reading" do
            allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(500)

            expect {
              RecurringVehicleMaintenanceCompliance.generate!
            }.to change(VehicleMaintenanceCompliance, :count).by(1)

            # It should add 1 new 500-mile occurrence due at 6500 miles
            expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 6500
          end
        end
      end

      describe "when compliance based scheduling is preferred" do
        before do
          @recurrence.update_columns compliance_based_scheduling: true
          @vehicle = create :vehicle, provider: @provider
        end

        describe "without prior event occurrences" do
          it "schedules only one event based on the recurrence_mileage and the vehicle's last_odometer_reading (no previous occurrences exists that could be completed)" do
            expect {
              RecurringVehicleMaintenanceCompliance.generate!
            }.to change(VehicleMaintenanceCompliance, :count).by(1)

            expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 500            
          end

          it "schedules one new event on schedule when the vehicle's last_odometer_reading is not 0" do
            allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

            expect {
              RecurringVehicleMaintenanceCompliance.generate!
            }.to change(VehicleMaintenanceCompliance, :count).by(1)

            expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 1500
          end
        end

        describe "with prior event occurrences" do
          before do
            # Creates 1 occurrence due after 500 miles
            RecurringVehicleMaintenanceCompliance.generate!
          end

          describe "when the previous occurrence is still incomplete" do
            it "schedules no new events, regardless of the vehicle's last_odometer_reading" do
              allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

              expect {
                RecurringVehicleMaintenanceCompliance.generate!
              }.not_to change(VehicleMaintenanceCompliance, :count)
            end
          end

          describe "when the previous occurrence is complete" do
            before do
              @vehicle.vehicle_maintenance_compliances.last.update_attributes compliance_date: Date.current, compliance_mileage: 499
            end

            it "schedules 1 new event based on the last due_mileage, regardless of the vehicle's last_odometer_reading" do
              allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)
              
              expect {
                RecurringVehicleMaintenanceCompliance.generate!
              }.to change(VehicleMaintenanceCompliance, :count).by(1)

              expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 999
            end
          end
        end
      end
    end

    describe "when the recurrence_type is 'both'" do
      before do
        # Time.now is now frozen at Monday, June 1, 2015
        Timecop.freeze(Date.parse("2015-06-01"))

        # Start date is Tuesday, June 2, 2015
        @recurrence = create :recurring_vehicle_maintenance_compliance,
          recurrence_type: "both",
          recurrence_frequency: 2,
          recurrence_schedule: "weeks",
          recurrence_mileage: 500,
          start_date: Date.parse("2015-06-02"),
          future_start_rule: "immediately",
          compliance_based_scheduling: false

        @provider = @recurrence.provider
      end

      after do
        Timecop.return
      end
      
      describe "when frequency based scheduling is preferred" do
        describe "for owners that already exist when the recurrence is created" do
          before do
            @vehicle = create :vehicle, provider: @provider
          end

          describe "without prior event occurrences" do
            it "schedules new events on a schedule based on the start_date, recurrence_mileage and the vehicle's last_odometer_reading, up to 6 months and 6000 miles out" do
              # Time is still frozen at Monday, June 1, 2015
              # Starting from Tue, Jun 2, 2015, bi-weekly occurrences over
              # the next 6 months should include:
              expected_occurrences = [
                ["2015-06-02", 500], ["2015-06-16", 1000], ["2015-06-30", 1500],
                ["2015-07-14", 2000], ["2015-07-28", 2500], ["2015-08-11", 3000], 
                ["2015-08-25", 3500], ["2015-09-08", 4000], ["2015-09-22", 4500],
                ["2015-10-06", 5000], ["2015-10-20", 5500], ["2015-11-03", 6000]
              ]

              expect {
                RecurringVehicleMaintenanceCompliance.generate!
              }.to change(VehicleMaintenanceCompliance, :count).by(12)

              expected_occurrences.each do |expected_date, expected_mileage|
                expect(@vehicle.vehicle_maintenance_compliances.where(due_date: expected_date, due_mileage: expected_mileage)).to exist
              end
            end

            it "won't schedule anything when the start_date is more than 6 months away" do
              @recurrence.update_columns start_date: 7.months.from_now
              expect {
                RecurringVehicleMaintenanceCompliance.generate!
              }.not_to change(VehicleMaintenanceCompliance, :count)
            end

            it "won't schedule anything when the recurrence_mileage is more than 6000 miles from the vehicle's last_odometer_reading" do
              @recurrence.update_columns recurrence_mileage: 7000
              expect {
                RecurringVehicleMaintenanceCompliance.generate!
              }.not_to change(VehicleMaintenanceCompliance, :count)
            end

            it "will only schedule one event when the recurrence frequency is is greater than 6 months" do
              @recurrence.update_columns recurrence_frequency: 7, recurrence_schedule: "months"
              expect {
                RecurringVehicleMaintenanceCompliance.generate!
              }.to change(VehicleMaintenanceCompliance, :count).by(1)
            end

            it "will only schedule one event when the recurrence_mileage means the second occurrence will fall outside of 6000 miles from the vehicle's last_odometer_reading" do
              @recurrence.update_attributes recurrence_mileage: 3001
              expect {
                RecurringVehicleMaintenanceCompliance.generate!
              }.to change(VehicleMaintenanceCompliance, :count).by(1)
            end

            it "will only schedule one event when the start_date means the second occurrence will fall outside of 6 months" do
              @recurrence.update_columns start_date: 3.months.from_now, recurrence_frequency: 4, recurrence_schedule: "months"
              expect {
                RecurringVehicleMaintenanceCompliance.generate!
              }.to change(VehicleMaintenanceCompliance, :count).by(1)
            end
          end

          describe "with prior event occurrences" do
            before do
              # Time is still frozen at Monday, June 1, 2015
              # Creates 12 bi-weekly occurrences due from 2015-06-02 to 
              # 2015-11-03
              RecurringVehicleMaintenanceCompliance.generate!
            end

            it "won't schedule anything if the vehicle's last_odometer_reading hasn't increased by more than the recurrence_mileage since the last time events were generated" do
              allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(499)

              # Travel 1 week into the future, to June 8, 2015
              Timecop.freeze(Date.parse("2015-06-08")) do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.not_to change(VehicleMaintenanceCompliance, :count)
              end
            end

            it "schedules new events on a schedule based on the due date and the vehicle's last_odometer_reading" do
              allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(500)

              # Travel 1 week into the future, to June 8, 2015
              Timecop.freeze(Date.parse("2015-06-08")) do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                # It should add 1 new bi-monthly occurrences due on 2015-11-17
                # and at 6500 miles
                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-17")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 6500
              end
            end
          end
        end

        describe "for owners created after the recurrence is created" do
          before do
            # Time is still frozen at Monday, June 1, 2015
            # Creates 12 bi-weekly occurrences due from 2015-06-02 to 2015-11-03
            RecurringVehicleMaintenanceCompliance.generate!
          end

          describe "when it is still before the recurrence start_date" do
            before do
              # Time is still frozen at Monday, June 1, 2015
              @vehicle = create :vehicle, provider: @provider
            end
    
            describe "with a future_start_rule of 'immediately'" do
              it "should generate new events on schedule, starting with the recurrence start_date, recurrence_mileage and the vehicle's last_odometer_reading" do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(12)

                expect(@vehicle.vehicle_maintenance_compliances.first.due_date).to eq @recurrence.start_date
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 500
                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-03")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 6000
              end

              it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(12)

                expect(@vehicle.vehicle_maintenance_compliances.first.due_date).to eq @recurrence.start_date
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 1500
                
                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-03")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 7000
              end
            end

            describe "with a future_start_rule of 'on_schedule'" do
              before do
                @recurrence.update_columns future_start_rule: "on_schedule"
              end
      
              it "should generate new events on schedule, starting with the recurrence start_date, recurrence_mileage and the vehicle's last_odometer_reading" do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(12)

                expect(@vehicle.vehicle_maintenance_compliances.first.due_date).to eq @recurrence.start_date
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 500
                
                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-03")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 6000
              end

              it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(12)

                expect(@vehicle.vehicle_maintenance_compliances.first.due_date).to eq @recurrence.start_date
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 1500
                
                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-03")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 7000
              end
            end

            describe "with a future_start_rule of 'time_span'" do
              before do
                @recurrence.update_columns future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 10
              end
      
              it "should generate new events on schedule, starting with the recurrence start_date, recurrence_mileage and the vehicle's last_odometer_reading" do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(12)

                expect(@vehicle.vehicle_maintenance_compliances.first.due_date).to eq @recurrence.start_date
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 500
                
                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-03")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 6000
              end

              it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(12)

                expect(@vehicle.vehicle_maintenance_compliances.first.due_date).to eq @recurrence.start_date
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 1500
                
                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-03")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 7000
              end
            end
          end

          describe "when it is after the recurrence start_date" do
            before do
              # Travel 1 week into the future, to June 8, 2015
              Timecop.freeze(Date.parse("2015-06-08"))

              @vehicle = create :vehicle, provider: @provider
            end
    
            after do
              Timecop.return
            end
    
            describe "with a future_start_rule of 'immediately'" do
              it "should generate new events on schedule, starting immediately" do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(12)

                expect(@vehicle.vehicle_maintenance_compliances.first.due_date).to eq Date.parse("2015-06-08")
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 500

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-09")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 6000
              end

              it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(12)

                expect(@vehicle.vehicle_maintenance_compliances.first.due_date).to eq Date.parse("2015-06-08")
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 1500
                
                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-09")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 7000
              end
            end

            describe "with a future_start_rule of 'on_schedule'" do
              before do
                @recurrence.update_columns future_start_rule: "on_schedule"
              end
      
              it "should generate new events on schedule, starting with the next occurrence from today" do            
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(12)

                expect(@vehicle.vehicle_maintenance_compliances.first.due_date).to eq Date.parse("2015-06-16")
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 500

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-17")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 6000
              end

              it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(12)

                expect(@vehicle.vehicle_maintenance_compliances.first.due_date).to eq Date.parse("2015-06-16")
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 1500
                
                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-17")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 7000
              end
            end

            describe "with a future_start_rule of 'time_span'" do
              before do
                @recurrence.update_columns future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 10
              end
      
              it "should generate new events on schedule, with the first occurrence starting after the time span from today" do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(12)

                expect(@vehicle.vehicle_maintenance_compliances.first.due_date).to eq Date.parse("2015-06-18")
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 500

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-19")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 6000
              end

              it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(12)

                expect(@vehicle.vehicle_maintenance_compliances.first.due_date).to eq Date.parse("2015-06-18")
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 1500
                
                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-11-19")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 7000
              end
            end
          end
        end
      end

      describe "when compliance based scheduling is preferred" do
        before do
          @recurrence.update_columns compliance_based_scheduling: true
        end

        describe "for owners that already exist when the recurrence is created" do
          before do
            @vehicle = create :vehicle, provider: @provider
          end

          describe "without prior event occurrences" do
            it "schedules only one event on the start_date, recurrence_mileage and the vehicle's last_odometer_reading (no previous occurrences exists that could be completed)" do
              expect {
                RecurringVehicleMaintenanceCompliance.generate!
              }.to change(VehicleMaintenanceCompliance, :count).by(1)

              expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq @recurrence.start_date
              expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 500
            end

            it "schedules one new event on schedule when the vehicle's last_odometer_reading is not 0" do
              allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

              expect {
                RecurringVehicleMaintenanceCompliance.generate!
              }.to change(VehicleMaintenanceCompliance, :count).by(1)

              expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq @recurrence.start_date
              expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 1500
            end
          end

          describe "with prior event occurrences" do
            before do
              # Time is still frozen at Monday, June 1, 2015
              # Creates 1 occurrence due on 2015-06-02
              RecurringVehicleMaintenanceCompliance.generate!
            end

            describe "when the previous occurrence is still incomplete" do
              it "schedules no new events, regardless of the vehicle's last_odometer_reading" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                # Travel 2 weeks into the future, to June 15, 2015
                Timecop.freeze(2.weeks.from_now) do
                  expect {
                    RecurringVehicleMaintenanceCompliance.generate!
                  }.not_to change(VehicleMaintenanceCompliance, :count)
                end
              end
            end

            describe "when the previous occurrence is complete" do
              before do
                # Time is still frozen at Monday, June 1, 2015
                @vehicle.vehicle_maintenance_compliances.last.update_attributes compliance_date: Date.current, compliance_mileage: 499
              end

              it "schedules 1 new event based on the last due_date and due_mileage, regardless of the vehicle's last_odometer_reading" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                # Travel 2 weeks into the future, to June 15, 2015
                Timecop.freeze(2.weeks.from_now) do
                  expect {
                    RecurringVehicleMaintenanceCompliance.generate!
                  }.to change(VehicleMaintenanceCompliance, :count).by(1)

                  # Last occurrence was due 2015-06-02, completed 2015-06-01
                  # It should add 1 new occurrence due on 2015-06-15 and at 999 
                  # miles
                  expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-06-15")
                  expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 999
                end
              end
            end
          end
        end

        describe "for owners created after the recurrence is created" do
          before do
            # Time is still frozen at Monday, June 1, 2015
            # Creates 12 bi-weekly occurrences due from 2015-06-02 to 2015-11-03
            RecurringVehicleMaintenanceCompliance.generate!
          end

          describe "when it is still before the recurrence start_date" do
            before do
              # Time is still frozen at Monday, June 1, 2015
              @vehicle = create :vehicle, provider: @provider
            end
    
            describe "with a future_start_rule of 'immediately'" do
              it "should generate the 1st event based on the recurrence start_date, recurrence_mileage and the vehicle's last_odometer_reading" do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq @recurrence.start_date
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 500
              end

              it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq @recurrence.start_date
                expect(@vehicle.vehicle_maintenance_compliances.first.due_mileage).to eq 1500
              end
            end

            describe "with a future_start_rule of 'on_schedule'" do
              before do
                @recurrence.update_columns future_start_rule: "on_schedule"
              end
      
              it "should generate the 1st event based on the recurrence start_date, recurrence_mileage and the vehicle's last_odometer_reading" do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq @recurrence.start_date
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 500
              end
              
              it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq @recurrence.start_date
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 1500
              end
            end

            describe "with a future_start_rule of 'time_span'" do
              before do
                @recurrence.update_columns future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 10
              end
      
              it "should generate the 1st event based on the recurrence start_date, recurrence_mileage and the vehicle's last_odometer_reading" do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq @recurrence.start_date
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 500
              end
              
              it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq @recurrence.start_date
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 1500
              end
            end
          end

          describe "when it is after the recurrence start_date" do
            before do
              # Travel 1 week into the future, to June 8, 2015
              Timecop.freeze(Date.parse("2015-06-08"))

              @vehicle = create :vehicle, provider: @provider
            end
    
            after do
              Timecop.return
            end
    
            describe "with a future_start_rule of 'immediately'" do
              it "should generate one new event, starting immediately" do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-06-08")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 500
              end

              it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-06-08")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 1500
              end
            end

            describe "with a future_start_rule of 'on_schedule'" do
              before do
                @recurrence.update_columns future_start_rule: "on_schedule"
              end
      
              it "should generate one new event, starting with the next occurrence from today" do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-06-16")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 500
              end

              it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-06-16")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 1500
              end
            end

            describe "with a future_start_rule of 'time_span'" do
              before do
                @recurrence.update_columns future_start_rule: "time_span", future_start_schedule: "days", future_start_frequency: 10
              end
      
              it "should generate one new event starting after the time span from today" do
                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-06-18")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 500
              end

              it "schedules new events on schedule when the vehicle's last_odometer_reading is not 0, up to 6000 miles out" do
                allow_any_instance_of(Vehicle).to receive(:last_odometer_reading).and_return(1234)

                expect {
                  RecurringVehicleMaintenanceCompliance.generate!
                }.to change(VehicleMaintenanceCompliance, :count).by(1)

                expect(@vehicle.vehicle_maintenance_compliances.last.due_date).to eq Date.parse("2015-06-18")
                expect(@vehicle.vehicle_maintenance_compliances.last.due_mileage).to eq 1500
              end
            end
          end
        end
      end
    end
  end
end
