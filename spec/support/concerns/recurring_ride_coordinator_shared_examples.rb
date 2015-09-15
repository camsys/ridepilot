require 'spec_helper'

# For model specs
RSpec.shared_examples "a recurring ride coordinator" do
  describe "instance" do
    before do
      # Set @occurrence_scheduler_association in the described class
      fail "@occurrence_scheduler_association instance variable required" unless defined? @occurrence_scheduler_association
      @occurrence_scheduler_class = @occurrence_scheduler_association.to_s.camelize.constantize
      @occurrence_scheduler_class_factory = @occurrence_scheduler_class.name.underscore.to_sym
      @occurrence_scheduler_association_id = "#{@occurrence_scheduler_association}_id"

      # Set @occurrence_date_attribute in the described class
      fail "@occurrence_date_attribute instance variable required" unless defined? @occurrence_date_attribute

      @described_class_factory = described_class.name.underscore.to_sym
    end

    describe "DAYS_OF_WEEK" do
      it "contains a list of the days of the week" do
        expect(described_class::DAYS_OF_WEEK).to include "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
      end
    
      it "defines a method that checks whether it repeats for each given day of the week" do
        coordinator = build @described_class_factory
        expect(coordinator).to respond_to :repeats_sundays
        expect(coordinator).to respond_to :repeats_sundays=
        expect(coordinator).to respond_to :repeats_mondays
        expect(coordinator).to respond_to :repeats_mondays=
        expect(coordinator).to respond_to :repeats_tuesdays
        expect(coordinator).to respond_to :repeats_tuesdays=
        expect(coordinator).to respond_to :repeats_wednesdays
        expect(coordinator).to respond_to :repeats_wednesdays=
        expect(coordinator).to respond_to :repeats_thursdays
        expect(coordinator).to respond_to :repeats_thursdays=
        expect(coordinator).to respond_to :repeats_fridays
        expect(coordinator).to respond_to :repeats_fridays=
        expect(coordinator).to respond_to :repeats_saturdays
        expect(coordinator).to respond_to :repeats_saturdays=
      end
    end
  
    describe "#repetition_driver_id=" do
      before do
        @coordinator = build @described_class_factory
      end
    
      it "sets the @repetition_driver_id instance variable" do
        expect(@coordinator.instance_variable_get("@repetition_driver_id")).to be_nil
        @coordinator.repetition_driver_id = 5
        expect(@coordinator.instance_variable_get("@repetition_driver_id")).to eq 5
      end
    
      it "converts blank values ('') to nil" do
        @coordinator.repetition_driver_id = ""
        expect(@coordinator.instance_variable_get("@repetition_driver_id")).to be_nil
      end
    
      it "converts non-blank values to integers" do
        @coordinator.repetition_driver_id = "5"
        expect(@coordinator.instance_variable_get("@repetition_driver_id")).to eq 5
      end
    end

    describe "#repetition_driver_id" do
      before do
        @coordinator = build @described_class_factory
      end
    
      it "returns the @repetition_driver_id instance variable if it's present" do
        @coordinator.instance_variable_set "@repetition_driver_id", 5
        expect(@coordinator.repetition_driver_id).to eq 5
      end

      it "returns the scheduler's driver_id if @repetition_driver_id is nil and the scheduler is present" do
        driver = create :driver
        @coordinator.send "#{@occurrence_scheduler_association}=", create(@occurrence_scheduler_class_factory, driver: driver)
        expect(@coordinator.repetition_driver_id).to eq driver.id
      end

      it "sets the @repetition_driver_id instance variable if it is nil and the scheduler is present" do
        driver = create :driver
        @coordinator.send "#{@occurrence_scheduler_association}=", create(@occurrence_scheduler_class_factory, driver: driver)
        expect(@coordinator.repetition_driver_id).to eq driver.id
        expect(@coordinator.instance_variable_get("@repetition_driver_id")).to eq driver.id
      end
    end

    describe "#repetition_vehicle_id=" do
      before do
        @coordinator = build @described_class_factory
      end
    
      it "sets the @repetition_vehicle_id instance variable" do
        expect(@coordinator.instance_variable_get("@repetition_vehicle_id")).to be_nil
        @coordinator.repetition_vehicle_id = 5
        expect(@coordinator.instance_variable_get("@repetition_vehicle_id")).to eq 5
      end
    
      it "converts blank values ('') to nil" do
        @coordinator.repetition_vehicle_id = ""
        expect(@coordinator.instance_variable_get("@repetition_vehicle_id")).to be_nil
      end

      it "converts non-blank values to integers" do
        @coordinator.repetition_vehicle_id = "5"
        expect(@coordinator.instance_variable_get("@repetition_vehicle_id")).to eq 5
      end
    end

    describe "#repetition_vehicle_id" do
      before do
        @coordinator = build @described_class_factory
      end
    
      it "returns the @repetition_vehicle_id instance variable if it's present" do
        @coordinator.instance_variable_set "@repetition_vehicle_id", 5
        expect(@coordinator.repetition_vehicle_id).to eq 5
      end
    
      it "returns the scheduler's vehicle_id if @repetition_vehicle_id is nil and the scheduler is present" do
        vehicle = create :vehicle
        @coordinator.send "#{@occurrence_scheduler_association}=", create(@occurrence_scheduler_class_factory, vehicle: vehicle)
        expect(@coordinator.repetition_vehicle_id).to eq vehicle.id
      end

      it "sets the @repetition_vehicle_id instance variable if it is nil and the scheduler is present" do
        vehicle = create :vehicle
        @coordinator.send "#{@occurrence_scheduler_association}=", create(@occurrence_scheduler_class_factory, vehicle: vehicle)
        expect(@coordinator.repetition_vehicle_id).to eq vehicle.id
        expect(@coordinator.instance_variable_get("@repetition_vehicle_id")).to eq vehicle.id
      end
    end

    describe "#repetition_interval=" do
      before do
        @coordinator = build @described_class_factory
      end

      it "sets the @repetition_interval instance variable" do
        expect(@coordinator.instance_variable_get("@repetition_interval")).to be_nil
        @coordinator.repetition_interval = 5
        expect(@coordinator.instance_variable_get("@repetition_interval")).to eq 5
      end

      it "converts values to integers" do
        @coordinator.repetition_interval = "5"
        expect(@coordinator.instance_variable_get("@repetition_interval")).to eq 5
      end
    end

    describe "#repetition_interval" do
      before do
        @coordinator = build @described_class_factory
      end

      it "returns the @repetition_interval instance variable if it's present" do
        @coordinator.instance_variable_set "@repetition_interval", 5
        expect(@coordinator.repetition_interval).to eq 5
      end
    
      it "returns the scheduler's schedule_attributes.interval if @repetition_interval is nil and the scheduler is present" do
        @coordinator.send "#{@occurrence_scheduler_association}=", create(@occurrence_scheduler_class_factory, schedule_attributes: {repeat: 1, interval: 5, interval_unit: "day"})
        expect(@coordinator.repetition_interval).to eq 5
      end
    
      it "sets the @repetition_interval instance variable if it is nil and the scheduler is present" do
        @coordinator.send "#{@occurrence_scheduler_association}=", create(@occurrence_scheduler_class_factory, schedule_attributes: {repeat: 1, interval: 5, interval_unit: "day"})
        expect(@coordinator.repetition_interval).to eq 5
        expect(@coordinator.instance_variable_get("@repetition_interval")).to eq 5
      end

      it "returns 1 if @repetition_interval is nil and the scheduler is not present" do
        expect(@coordinator.instance_variable_get("@repetition_interval")).to be_nil
        expect(@coordinator.send(@occurrence_scheduler_association)).to be_nil
        expect(@coordinator.repetition_interval).to eq 1
      end
    end

    describe "#is_recurring_ride_coordinator?" do
      before do
        @coordinator = build @described_class_factory
      end
    
      it "is true if repetition_interval is greater than 0 and at least one of the repeats_x methods returns true" do
        allow(@coordinator).to receive(:repetition_interval).and_return(1)
        allow(@coordinator).to receive(:repeats_sundays).and_return(true)
        expect(@coordinator.is_recurring_ride_coordinator?).to be_truthy
      end

      it "is false if repetition_interval <= 0, even if one of the repeats_x methods returns true" do
        allow(@coordinator).to receive(:repeats_sundays).and_return(true)
        @coordinator.repetition_interval = 0
        expect(@coordinator.is_recurring_ride_coordinator?).to be_falsey
        @coordinator.repetition_interval = 1
        expect(@coordinator.is_recurring_ride_coordinator?).to be_truthy
      end
    
      it "is false if none of the repeats_x methods return true, even if repetition_interval > 0" do
        allow(@coordinator).to receive(:repetition_interval).and_return(1)
        expect(@coordinator.is_recurring_ride_coordinator?).to be_falsey
        @coordinator.repeats_sundays = true
        expect(@coordinator.is_recurring_ride_coordinator?).to be_truthy
      end
    end    

    describe "after validation with repetition" do
      before do
        @driver = create :driver
        @vehicle = create :vehicle, default_driver: @driver
      end
      
      describe "when creating a coordinator with repetition data" do
        before do
          # Freeze date at Sun, 30 Aug 2015, 12:00 PM
          Timecop.freeze(Time.parse("2015-08-30 12:00").in_time_zone)
        
          @coordinator = build @described_class_factory,
            # Schedule first occurrence on Mon, 31 Sep 2015
            @occurrence_date_attribute => Time.parse("2015-08-31 12:00").in_time_zone,
            :repeats_mondays => true, 
            :repeats_tuesdays => false,
            :repeats_wednesdays => false,
            :repeats_thursdays => false,
            :repeats_fridays => false,
            :repeats_saturdays => false,
            :repeats_sundays => false,
            :repetition_vehicle_id => @vehicle.id,
            :repetition_driver_id => @driver.id,
            :repetition_interval => 1
        end
      
        after do
          Timecop.return
        end

        it "should create a scheduler when saved" do
          expect(@occurrence_scheduler_class.count).to eq 0
          expect {
            @coordinator.save
            expect(@coordinator.send(@occurrence_scheduler_association)).not_to be_nil
          }.to change(@occurrence_scheduler_class, :count).by(1)
          expect(@coordinator.send(@occurrence_scheduler_association_id)).not_to be_nil
        end

        it "should instantiate coordinators for 21 days out" do
          # Time is still frozen at Sun, 30 Aug 2015. 3 weeks out is
          # Sun, 20 Sep 2015. With weekly repeats on Mondays, beginning Mon, 31 
          # Aug 2015, this gives us:
          #   2015-08-31
          #   2015-09-07
          #   2015-09-14
          @coordinator.save
          id = @coordinator.send(@occurrence_scheduler_association_id)
          # The occurrence we just created, plus 2 more
          expect(described_class.where(@occurrence_scheduler_association_id => id).count).to eq 3
        end
      end

      describe "when updating a future coordinator with repetition data" do
        before do
          # Freeze date at Sun, 30 Aug 2015, 12:00 PM
          Timecop.freeze(Time.parse("2015-08-30 12:00").in_time_zone)

          @coordinator = create @described_class_factory,
            # Schedule first occurrence on Mon, 31 Sep 2015
            # With weekly repeats on Mondays, this gives us:
            #   2015-08-31
            #   2015-09-07
            #   2015-09-14
            @occurrence_date_attribute => Time.parse("2015-08-31 12:00").in_time_zone,
            :repeats_mondays => true, 
            :repeats_tuesdays => false,
            :repeats_wednesdays => false,
            :repeats_thursdays => false,
            :repeats_fridays => false,
            :repeats_saturdays => false,
            :repeats_sundays => false,
            :repetition_vehicle_id => @vehicle.id,
            :repetition_driver_id => @driver.id,
            :repetition_interval => 1

          @coordinator.repeats_mondays = false
          @coordinator.repeats_tuesdays = true
          @coordinator.save
          @coordinator.reload
        end
      
        after do
          Timecop.return
        end

        it "should have the correct repeating coordinator attributes" do
          expect(@coordinator.send(@occurrence_scheduler_association).schedule_attributes.monday).to be_nil
          expect(@coordinator.send(@occurrence_scheduler_association).schedule_attributes.tuesday).to eq 1
        end

        it "should have new child coordinators on the correct day" do
          # Time is still frozen at Sun, 30 Aug 2015. 3 weeks out is
          # Sun, 20 Sep 2015. With weekly repeats now on Tuesdays, beginning 
          # Mon, 31 Aug 2015, this gives us:
          #   2015-09-01
          #   2015-09-08
          #   2015-09-15
          # Not including the original (which was created on a Monday), we 
          # should see 3 new occurrences
          expect(
            described_class.where(
              @occurrence_scheduler_association_id => @coordinator.send(
                @occurrence_scheduler_association_id
              )
            ).select{ |c| c.send(@occurrence_date_attribute).strftime("%u") == "2" }.size
          ).to eq 3
        end

        it "should have no child coordinators on the old day" do
          # We should see only the original (which was created on a Monday)
          expect(
            described_class.where(
              @occurrence_scheduler_association_id => @coordinator.send(
                @occurrence_scheduler_association_id
              )
            ).select{ |c| c.send(@occurrence_date_attribute).strftime("%u") == "1" }.size
          ).to eq 1
        end

        it "should tell me the correct repetition data when reloading the coordinator" do
          @coordinator.reload
          expect(@coordinator.repeats_mondays).to be_falsey
          expect(@coordinator.repeats_tuesdays).to be_truthy
          expect(@coordinator.repetition_vehicle_id).to eq @vehicle.id
          expect(@coordinator.repetition_driver_id).to eq @driver.id
        end
      end
   
      describe "when updating a past coordinator with repetition data," do
        before do
          # Freeze date at Sun, 30 Aug 2015, 12:00 PM
          Timecop.freeze(Time.parse("2015-08-30 12:00").in_time_zone) do
            @coordinator = create @described_class_factory,
              # Schedule first occurrence on Mon, 31 Sep 2015
              # With weekly repeats on Mondays, this gives us:
              #   2015-08-31
              #   2015-09-07
              #   2015-09-14
              @occurrence_date_attribute => Time.parse("2015-08-31 12:00").in_time_zone,
              :repeats_mondays => true, 
              :repeats_tuesdays => false,
              :repeats_wednesdays => false,
              :repeats_thursdays => false,
              :repeats_fridays => false,
              :repeats_saturdays => false,
              :repeats_sundays => false,
              :repetition_vehicle_id => @vehicle.id,
              :repetition_driver_id => @driver.id,
              :repetition_interval => 1
          end
          
          # Now advance time two weeks, to Sun, 13 Sep 2015
          Timecop.freeze(Time.parse("2015-09-13 12:00").in_time_zone)
          
          @coordinator.repeats_mondays = false
          @coordinator.repeats_tuesdays = true
          @coordinator.save
          @coordinator.reload
        end

        after do
          Timecop.return
        end

        it "should have the correct repeating coordinator attributes" do
          expect(@coordinator.send(@occurrence_scheduler_association).schedule_attributes.monday).to be_nil
          expect(@coordinator.send(@occurrence_scheduler_association).schedule_attributes.tuesday).to eq 1
        end

        it "should have new child coordinators on the correct day" do
          # Time is still frozen at Sun, 13 Sep 2015. 3 weeks out is
          # Sun, 04 Oct 2015. With weekly repeats now on Tuesdays, beginning 
          # Sun, 13 Sep 2015, this gives us:
          #   2015-09-15
          #   2015-09-22
          #   2015-09-29
          # Not including the originals (which were created on a Monday), we 
          # should see 3 new occurrences
          expect(
            described_class.where(
              @occurrence_scheduler_association_id => @coordinator.send(
                @occurrence_scheduler_association_id
              )
            ).where().not(
              id: @coordinator.id
            ).select{ |c| c.send(@occurrence_date_attribute).strftime("%u") == "2" }.size
          ).to eq 3
        end

        it "should have no child coordinators on the old day beyond Sun, 13 Sep 2015" do
          expect(
            described_class.after_today.where(
              @occurrence_scheduler_association_id => @coordinator.send(
                @occurrence_scheduler_association_id
              )
            ).select{ |c| c.send(@occurrence_date_attribute).strftime("%u") == "1" }.size
          ).to eq 0
        end

        it "should retain child coordinators on the old day on or before Sun, 13 Sep 2015" do
          expect(
            described_class.today_and_prior.where(
              @occurrence_scheduler_association_id => @coordinator.send(
                @occurrence_scheduler_association_id
              )
            ).select{ |c| c.send(@occurrence_date_attribute).strftime("%u") == "1" }.size
          ).to eq 2
        end

        it "should tell me the correct repeating trip data when reloading the trip" do
          @coordinator.reload
          expect(@coordinator.repeats_mondays).to be_falsey
          expect(@coordinator.repeats_tuesdays).to be_truthy
          expect(@coordinator.repetition_vehicle_id).to eq @vehicle.id
          expect(@coordinator.repetition_driver_id).to eq @driver.id
        end
      end

      describe "when I clear out the repetition data" do
        before do
          # Freeze date at Sun, 30 Aug 2015, 12:00 PM
          Timecop.freeze(Time.parse("2015-08-30 12:00").in_time_zone) do
            @coordinator = create @described_class_factory,
              # Schedule first occurrence on Mon, 31 Sep 2015
              # With weekly repeats on Mondays, this gives us:
              #   2015-08-31
              #   2015-09-07
              #   2015-09-14
              @occurrence_date_attribute => Time.parse("2015-08-31 12:00").in_time_zone,
              :repeats_mondays => true, 
              :repeats_tuesdays => false,
              :repeats_wednesdays => false,
              :repeats_thursdays => false,
              :repeats_fridays => false,
              :repeats_saturdays => false,
              :repeats_sundays => false,
              :repetition_vehicle_id => @vehicle.id,
              :repetition_driver_id => @driver.id,
              :repetition_interval => 1
          end
          
          # Now advance time two weeks, to Sun, 13 Sep 2015
          Timecop.freeze(Time.parse("2015-09-13 12:00").in_time_zone)
          
          @coordinator.repeats_mondays = false
          @scheduler_id = @coordinator.send(@occurrence_scheduler_association_id)
          @coordinator.save
        end

        after do
          Timecop.return
        end

        it "should remove all future coordinators after the coordinator and delete the scheduler record" do 
          expect(described_class.after_today.where(@occurrence_scheduler_association_id => @scheduler_id).count).to eq 0
          expect(@occurrence_scheduler_class.find_by_id(@scheduler_id)).to be_nil
        end

        it "should retain child coordinators on or before Sun, 13 Sep 2015" do
          expect(
            described_class.today_and_prior.where(
              @occurrence_scheduler_association_id => @coordinator.send(
                @occurrence_scheduler_association_id
              )
            ).select{ |c| c.send(@occurrence_date_attribute).strftime("%u") == "1" }.size
          ).to eq 2
        end
      end
    end
  end
end
