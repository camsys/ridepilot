require 'rails_helper'

RSpec.describe OperatingHours, type: :model do
  it "requires a day of the week" do
    hours = build :operating_hours, day_of_week: nil
    expect(hours.valid?).to be_falsey
    expect(hours.errors.keys).to include :day_of_week
  end

  it "requires a driver" do
    hours = build :operating_hours, driver: nil
    expect(hours.valid?).to be_falsey
    expect(hours.errors.keys).to include :driver
  end
  
  it "orders records by day_of_week" do
    hours_5 = create :operating_hours, day_of_week: 5
    hours_1 = create :operating_hours, day_of_week: 1
    hours_3 = create :operating_hours, day_of_week: 3
    hours_0 = create :operating_hours, day_of_week: 0
    
    expect(OperatingHours.all.to_a).to eql [hours_0, hours_1, hours_3, hours_5]
  end
  
  it "allows overnight hours up until 12:59am" do
    hours = build :operating_hours, start_time: "01:00", end_time: "00:59"
    expect(hours.valid?).to be_truthy
    expect(hours.is_regular_hours?).to be_truthy

    hours.end_time = "01:00"
    expect(hours.valid?).to be_falsey
    expect(hours.errors.keys).to include :end_time
  end
  
  it "can be unavailable" do
    hours = build :operating_hours, start_time: nil, end_time: nil
    expect(hours.valid?).to be_truthy
    expect(hours.is_unavailable?).to be_truthy
  end
  
  it "can be available 24 hours" do
    hours = build :operating_hours, start_time: "00:00", end_time: "00:00"
    expect(hours.valid?).to be_truthy
    expect(hours.is_24_hours?).to be_truthy
  end
  
  it "can make itself unavailable" do
    hours = build :operating_hours
    expect(hours.is_unavailable?).to be_falsey
    hours.make_unavailable
    expect(hours.is_unavailable?).to be_truthy
  end
  
  it "can make itself available 24 hours" do
    hours = build :operating_hours
    expect(hours.is_24_hours?).to be_falsey
    hours.make_24_hours
    expect(hours.is_24_hours?).to be_truthy
  end
  
  it "defines START_OF_DAY as string representation of 01:00 am" do
    expect(OperatingHours::START_OF_DAY).to be_a String
    expect(Time.zone.parse(OperatingHours::START_OF_DAY).hour).to eq 1
    expect(Time.zone.parse(OperatingHours::START_OF_DAY).min).to eq 0
  end
  
  it "defines END_OF_DAY as string representation of 00:59 am" do
    expect(OperatingHours::END_OF_DAY).to be_a String
    expect(Time.zone.parse(OperatingHours::END_OF_DAY).hour).to eq 0
    expect(Time.zone.parse(OperatingHours::END_OF_DAY).min).to eq 59
  end

  describe ".available_start_times" do
    before do
      @start_times = OperatingHours.available_start_times
    end
      
    it "returns an array" do
      expect(@start_times).to be_an Array
    end
    
    it "contains time values as strings" do
      expect(@start_times.first).to be_a String
    end
    
    it "starts at 1:00 am" do
      expect(@start_times.first).to eq "01:00:00"
    end

    it "defaults to 30 minute intervals" do
      expect(Time.zone.parse(@start_times.second) - Time.zone.parse(@start_times.first)).to eq 30.minutes
    end
  
    it "can accept an optional interval argument" do
      times = OperatingHours.available_start_times(interval: 1.hour)
      expect(Time.zone.parse(times.second) - Time.zone.parse(times.first)).to eq 1.hour
    end
        
    it "ends at 11:30 pm by default" do
      expect(@start_times.last).to eq "23:30:00"
    end
  end
  
  describe ".available_end_times" do
    before do
      @end_times = OperatingHours.available_end_times
    end
      
    it "returns an array" do
      expect(@end_times).to be_an Array
    end

    it "contains time values as strings" do
      expect(@end_times[0]).to be_a String
    end
    
    it "starts at 1:00 am" do
      expect(@end_times.first).to eq "01:00:00"
    end

    it "defaults to 30 minute intervals" do
      expect(Time.zone.parse(@end_times.second) - Time.zone.parse(@end_times.first)).to eq 30.minutes
    end
  
    it "can accept an optional interval argument" do
      times = OperatingHours.available_end_times(interval: 1.hour)
      expect(Time.zone.parse(times.second) - Time.zone.parse(times.first)).to eq 1.hour
    end
        
    it "ends at 12:30am by default, which is after midnight" do
      expect(@end_times.last).to eq "00:30:00"
      expect(@end_times).to include "00:00:00"
    end
  end
end
