require 'rails_helper'

RSpec.describe ReimbursementRateCalculator do
  before do
    @oaa = create :funding_source, name: "OAA"
    @ride_connection = create :funding_source, name: "Ride Connection"
    @trimet_non_medical = create :funding_source, name: "TriMet Non-Medical"
    @stf = create :funding_source, name: "STF"

    @wheelchair = create :service_level, name: "Wheelchair"
    @ambulatory = create :service_level, name: "Ambulatory"

    @provider = create :provider, oaa3b_per_ride_reimbursement_rate: 1,
      ride_connection_per_ride_reimbursement_rate: 2,
      trimet_per_ride_reimbursement_rate: 4,
      stf_van_per_ride_reimbursement_rate: 8,
      stf_taxi_per_ride_administrative_fee: 16,
      stf_taxi_per_ride_wheelchair_load_fee: 32,
      stf_taxi_per_mile_wheelchair_reimbursement_rate: 64,
      stf_taxi_per_ride_ambulatory_load_fee: 128,
      stf_taxi_per_mile_ambulatory_reimbursement_rate: 256

    @run = create :run

    @calculator = ReimbursementRateCalculator.new @provider
  end
  
  it "delegates reimbursement attributes to the provider" do
    expect(@calculator.oaa3b_per_ride_reimbursement_rate).to eq 1
    expect(@calculator.ride_connection_per_ride_reimbursement_rate).to eq 2
    expect(@calculator.trimet_per_ride_reimbursement_rate).to eq 4
    expect(@calculator.stf_van_per_ride_reimbursement_rate).to eq 8
    expect(@calculator.stf_taxi_per_ride_administrative_fee).to eq 16
    expect(@calculator.stf_taxi_per_ride_wheelchair_load_fee).to eq 32
    expect(@calculator.stf_taxi_per_mile_wheelchair_reimbursement_rate).to eq 64
    expect(@calculator.stf_taxi_per_ride_ambulatory_load_fee).to eq 128
    expect(@calculator.stf_taxi_per_mile_ambulatory_reimbursement_rate).to eq 256
  end

  describe "#reimbursements_due_for_trips_by_funding_source" do
    it "returns a hash of reimbursements due for a set of trips, separated by funding source" do
      reimbursements = @calculator.reimbursements_due_for_trips_by_funding_source @run.trips
      expect(reimbursements).to be_a Hash
      expect(reimbursements).to have_key :oaa3b
      expect(reimbursements).to have_key :rc
      expect(reimbursements).to have_key :trimet
      expect(reimbursements).to have_key :stf_van
      expect(reimbursements).to have_key :stf_taxi
      expect(reimbursements[:stf_taxi]).to have_key :administrative
      expect(reimbursements[:stf_taxi]).to have_key :wheelchair
      expect(reimbursements[:stf_taxi][:wheelchair]).to have_key :load_fee
      expect(reimbursements[:stf_taxi][:wheelchair]).to have_key :mileage
      expect(reimbursements[:stf_taxi]).to have_key :ambulatory
      expect(reimbursements[:stf_taxi][:ambulatory]).to have_key :load_fee
      expect(reimbursements[:stf_taxi][:ambulatory]).to have_key :mileage
    end
    
    it "calculates the cost of OAA trips" do
      create :trip, run: @run, funding_source: @oaa
      expect(@calculator.reimbursements_due_for_trips_by_funding_source(@run.trips)[:oaa3b]).to eq 1
    end
    
    it "calculates the cost of Ride Connection trips" do
      create :trip, run: @run, funding_source: @ride_connection
      expect(@calculator.reimbursements_due_for_trips_by_funding_source(@run.trips)[:rc]).to eq 2
    end
    
    it "calculates the cost of TriMet trips" do
      create :trip, run: @run, funding_source: @trimet_non_medical
      expect(@calculator.reimbursements_due_for_trips_by_funding_source(@run.trips)[:trimet]).to eq 4
    end
    
    it "calculates the cost of STF Van trips" do
      create :trip, run: @run, funding_source: @stf
      expect(@calculator.reimbursements_due_for_trips_by_funding_source(@run.trips)[:stf_van]).to eq 8
    end
    
    it "calculates the cost of STF Taxi trips" do
      create :cab_trip, run: @run, funding_source: @stf
      expect(@calculator.reimbursements_due_for_trips_by_funding_source(@run.trips)[:stf_taxi][:administrative]).to eq 16
    end
    
    it "calculates the cost of STF Taxi Wheelchair trips" do
      create :cab_trip, run: @run, funding_source: @stf, service_level: @wheelchair, mileage: 1
      expect(@calculator.reimbursements_due_for_trips_by_funding_source(@run.trips)[:stf_taxi][:wheelchair][:load_fee]).to eq 32
      expect(@calculator.reimbursements_due_for_trips_by_funding_source(@run.trips)[:stf_taxi][:wheelchair][:mileage]).to eq 64
    end

    it "calculates the cost of STF Taxi Ambulatory trips" do
      create :cab_trip, run: @run, funding_source: @stf, service_level: @ambulatory, mileage: 1
      expect(@calculator.reimbursements_due_for_trips_by_funding_source(@run.trips)[:stf_taxi][:ambulatory][:load_fee]).to eq 128
      expect(@calculator.reimbursements_due_for_trips_by_funding_source(@run.trips)[:stf_taxi][:ambulatory][:mileage]).to eq 256
    end
  end

  describe "#total_reimbursement_due_for_trips" do
    it "should return 0 when trips is empty" do
      expect(@calculator.total_reimbursement_due_for_trips []).to eq 0
    end

    it "should return 0 when no applicable trips exist (no applicable funding sources)" do
      trip = create :trip
      expect(@calculator.total_reimbursement_due_for_trips [trip]).to eq 0
    end
    
    it "should return a total based on a single applicable trip" do
      trip = create :trip, funding_source: @oaa
      expect(@calculator.total_reimbursement_due_for_trips trip).to eq 1
    end
    
    it "should return a total based on an array of applicable trips" do
      trips = [
        create(:trip, funding_source: @oaa),                                             # $1
        create(:trip, funding_source: @ride_connection),                                 # $2
        create(:trip, funding_source: @trimet_non_medical),                              # $4
        create(:trip, funding_source: @stf),                                             # $8
        create(:cab_trip, funding_source: @stf),                                         # $16 * 3
        create(:cab_trip, funding_source: @stf, service_level: @wheelchair, mileage: 1), # $32 + $64
        create(:cab_trip, funding_source: @stf, service_level: @ambulatory, mileage: 1), # $128 + $256
      ]
      expect(@calculator.total_reimbursement_due_for_trips trips).to eq 1 + 2 + 4 + 8 + (16 * 3) + 32 + 64 + 128 + 256
    end
    
    it "should return a total based on an ActiveRecord::Relation of applicable trips" do
      create :trip, run: @run, funding_source: @oaa                                             # $1
      create :trip, run: @run, funding_source: @ride_connection                                 # $2
      create :trip, run: @run, funding_source: @trimet_non_medical                              # $4
      create :trip, run: @run, funding_source: @stf                                             # $8
      create :cab_trip, run: @run, funding_source: @stf                                         # $16 * 3
      create :cab_trip, run: @run, funding_source: @stf, service_level: @wheelchair, mileage: 1 # $32 + $64
      create :cab_trip, run: @run, funding_source: @stf, service_level: @ambulatory, mileage: 1 # $128 + $256
      expect(@calculator.total_reimbursement_due_for_trips @run.trips).to eq 1 + 2 + 4 + 8 + (16 * 3) + 32 + 64 + 128 + 256
    end
  end
end
