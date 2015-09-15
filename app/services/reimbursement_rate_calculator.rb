class ReimbursementRateCalculator
  attr_reader :provider
  
  delegate :oaa3b_per_ride_reimbursement_rate, to: :provider
  delegate :ride_connection_per_ride_reimbursement_rate, to: :provider
  delegate :trimet_per_ride_reimbursement_rate, to: :provider
  delegate :stf_van_per_ride_reimbursement_rate, to: :provider
  delegate :stf_taxi_per_ride_administrative_fee, to: :provider
  delegate :stf_taxi_per_ride_wheelchair_load_fee, to: :provider
  delegate :stf_taxi_per_mile_wheelchair_reimbursement_rate, to: :provider
  delegate :stf_taxi_per_ride_ambulatory_load_fee, to: :provider
  delegate :stf_taxi_per_mile_ambulatory_reimbursement_rate, to: :provider

  def initialize(provider)
    @provider = provider
  end

  # Public for testability
  def reimbursements_due_for_trips_by_funding_source(trips)
    stats = stats_for_trips_by_funding_source trips
    {
      oaa3b:            reimbursement_from_stats(stats, oaa3b_per_ride_reimbursement_rate, :oaa3b),
      rc:               reimbursement_from_stats(stats, ride_connection_per_ride_reimbursement_rate, :rc),
      trimet:           reimbursement_from_stats(stats, trimet_per_ride_reimbursement_rate, :trimet),
      stf_van:          reimbursement_from_stats(stats, stf_van_per_ride_reimbursement_rate, :stf_van),
      stf_taxi: {
        administrative: reimbursement_from_stats(stats, stf_taxi_per_ride_administrative_fee, :stf_taxi, :all, :count),
        wheelchair: {
          load_fee:     reimbursement_from_stats(stats, stf_taxi_per_ride_wheelchair_load_fee, :stf_taxi, :wheelchair, :count),
          mileage:      reimbursement_from_stats(stats, stf_taxi_per_mile_wheelchair_reimbursement_rate, :stf_taxi, :wheelchair, :mileage)
        },
        ambulatory: {
          load_fee:     reimbursement_from_stats(stats, stf_taxi_per_ride_ambulatory_load_fee, :stf_taxi, :ambulatory, :count),
          mileage:      reimbursement_from_stats(stats, stf_taxi_per_mile_ambulatory_reimbursement_rate, :stf_taxi, :ambulatory, :mileage)
        }
      }
    }    
  end
  
  def total_reimbursement_due_for_trips(trips)
    reimbursements = reimbursements_due_for_trips_by_funding_source ensure_trips_relation trips
    reimbursements[:oaa3b] +
      reimbursements[:rc] +
      reimbursements[:trimet] +
      reimbursements[:stf_van] +
      reimbursements[:stf_taxi][:administrative] +
      reimbursements[:stf_taxi][:wheelchair][:load_fee] +
      reimbursements[:stf_taxi][:wheelchair][:mileage] +
      reimbursements[:stf_taxi][:ambulatory][:load_fee] +
      reimbursements[:stf_taxi][:ambulatory][:mileage]
  end

  private

  def stats_for_trips_by_funding_source(trips)
    {
      oaa3b:       trips.by_funding_source("OAA").collect(&:trip_count).sum,
      rc:          trips.by_funding_source("Ride Connection").collect(&:trip_count).sum,
      trimet:      trips.by_funding_source("TriMet Non-Medical").collect(&:trip_count).sum,
      stf_van:     trips.by_funding_source("STF").not_for_cab.collect(&:trip_count).sum,
      stf_taxi: {
        all: {
          count:   trips.by_funding_source("STF").for_cab.collect(&:trip_count).sum
        },
        wheelchair: {
          count:   trips.by_funding_source("STF").for_cab.by_service_level("Wheelchair").collect(&:trip_count).sum,
          mileage: trips.by_funding_source("STF").for_cab.by_service_level("Wheelchair").sum(:mileage)
        },
        ambulatory: {
          count:   trips.by_funding_source("STF").for_cab.by_service_level("Ambulatory").collect(&:trip_count).sum,
          mileage: trips.by_funding_source("STF").for_cab.by_service_level("Ambulatory").sum(:mileage)
        }
      }
    }
  end

  def reimbursement_from_stats(stats, rate, *keys)
    keys.inject(stats, :fetch) * rate.to_f
  end
  
  # A safety method that allows us to catch when trips is an array 
  # instead of a relation, and convert it to a relation instead.
  def ensure_trips_relation(trips)
    unless trips.is_a? ActiveRecord::Relation
      if trips.is_a?(Trip) or trips.is_a?(Array)
        trips = Trip.where id: Array(trips)
      else
        trips = Trip.none
      end
    end
    trips
  end
end