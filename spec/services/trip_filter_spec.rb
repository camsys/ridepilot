require 'rails_helper'

RSpec.describe TripFilter do
  before do 
    Date.beginning_of_week= :sunday
  end

  context "filter by pickup time" do 
    before do 
      start_date = Time.now.in_time_zone 
      end_date = start_date + 2.days
      filters = {
        start: start_date.to_i,
        end: end_date.to_i
      }
      @before_range_trip = create(:trip, pickup_time: start_date - 1.day)
      @after_range_trip = create(:trip, pickup_time: end_date + 1.day)
      @in_range_trip_1 = create(:trip, pickup_time: start_date)
      @in_range_trip_2 = create(:trip, pickup_time: end_date)

      @trip_filter = TripFilter.new(Trip.all, filters)
    end

    it "should return trips within pickup time filter range" do
      expect(@trip_filter.filter!).to eq([@in_range_trip_1, @in_range_trip_2])
    end

    it "should not return trips outside pickup time filter range" do
      expect(@trip_filter.filter!).to_not include(@before_range_trip)
      expect(@trip_filter.filter!).to_not include(@after_range_trip)
    end
  end

  context "filter by days of week" do 
    before do 
      @start_date = Time.now.in_time_zone.beginning_of_week

      (0..5).each do |n|
        create(:trip, pickup_time: @start_date + n.days)
      end

      @all_trips = Trip.all.order(:pickup_time)
    end

    it "should return all trips without days_of_week filter" do
      filters = {}
      expect(TripFilter.new(@all_trips).filter!.count).to eq(6)
    end

    it "should return all trips with all days_of_week" do
      filters = {days_of_week: '0,1,2,3,4,5,6'}
      expect(TripFilter.new(@all_trips, filters).filter!.count).to eq(6)
    end

    it "should return eligible trips within days_of_week filter (Sun, Wed, Fri)" do
      filters = {days_of_week: '0,2,4'}
      expect(TripFilter.new(@all_trips, filters).filter!.count).to eq(3)
    end

    it "should not return ineligible trips without days_of_week filter (Sun)" do
      filters = {days_of_week: '1,2,3,4,5'}
      filtered_trips = TripFilter.new(@all_trips, filters).filter!
      expect(filtered_trips.count).to eq(5)
      expect(filtered_trips).to_not include(@all_trips.first)
    end
  end 

  context "filter by vehicle" do 
    before do 
      base_pickup_time = Time.now.in_time_zone.beginning_of_week
      @cab_trip = create(:trip, cab: true, pickup_time: base_pickup_time)
      @run = create(:run)
      @non_cab_trip = create(:trip, cab: false, run: @run, pickup_time: base_pickup_time + 1.day)
    end

    it "should return all trips when no vehicle filter is specified" do 
      expect(TripFilter.new(Trip.all, {}).filter!.count).to eq(2)
    end

    it "should return trips with cab when cab filter is specified" do 
      expect(TripFilter.new(Trip.all, {vehicle_id: -1}).filter!).to eq([@cab_trip])
    end

    it "should return trips with non-cab vehicle when non-cab filter is specified" do 
      expect(TripFilter.new(Trip.all, {vehicle_id: @run.vehicle_id}).filter!).to eq([@non_cab_trip])
    end
  end

  context "filter by driver" do 
    before do 
      base_pickup_time = Time.now.in_time_zone.beginning_of_week
      @scheduled_run = create(:run)
      @non_scheduled_run = create(:run)
      @trip = create(:trip, run: @scheduled_run, pickup_time: base_pickup_time)
    end

    it "should return eligible trips when driver filter is specified" do 
      expect(TripFilter.new(Trip.all, {driver_id: @scheduled_run.driver.id}).filter!).to eq([@trip])
    end

    it "should not return ineligible trips when driver filter is specified" do 
      expect(TripFilter.new(Trip.all, {driver_id: @non_scheduled_run.driver.id}).filter!).to_not eq([@trip])
    end

  end 

  context "filter by scheduled status" do 
    before do 
      base_pickup_time = Time.now.in_time_zone.beginning_of_week
      @scheduled_run = create(:run)
      @scheduled_trip = create(:trip, run: @scheduled_run, pickup_time: base_pickup_time)
      @non_scheduled_trip = create(:trip, pickup_time: base_pickup_time + 1.day)
    end

    it "should return scheduled trips when scheduled status is specified" do 
      expect(TripFilter.new(Trip.all, {status_id: 1}).filter!).to eq([@scheduled_trip])
    end

    it "should return non-scheduled trips when non-scheduled status is specified" do 
      expect(TripFilter.new(Trip.all, {status_id: 2}).filter!).to eq([@non_scheduled_trip])
    end
  end

  context "filter by trip result" do 
    before do 
      base_pickup_time = Time.now.in_time_zone.beginning_of_week
      @cancel_trip_result = create(:trip_result, code: 'CANC')
      @cancelled_trip = create(:trip, pickup_time: base_pickup_time, trip_result: @cancel_trip_result)
      @non_scheduled_trip = create(:trip, pickup_time: base_pickup_time + 1.day)
    end

    it "should return cancelled trips when trip result filter is Cancelled" do 
      expect(TripFilter.new(Trip.all, {trip_result_id: @cancel_trip_result.id}).filter!).to eq([@cancelled_trip])
    end

    it "should return all trips when trip result filter is not specified" do 
      expect(TripFilter.new(Trip.all, {}).filter!).to eq([@cancelled_trip, @non_scheduled_trip])
    end
  end   

end
