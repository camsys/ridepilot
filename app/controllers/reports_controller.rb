require 'csv'

class Query
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_date
  attr_accessor :before_end_date
  attr_accessor :end_date
  attr_accessor :vehicle_id
  attr_accessor :driver_id
  attr_accessor :trip_display

  def convert_date(obj, base)
    return Date.new(obj["#{base}(1i)"].to_i,obj["#{base}(2i)"].to_i,(obj["#{base}(3i)"] || 1).to_i)
  end

  def initialize(params = {})
    now = Date.today
    @start_date = params[:start_date].try(:to_date) || Date.new(now.year, now.month, 1).prev_month
    if params[:before_end_date]
      @before_end_date = params[:before_end_date].to_date
      @end_date = params[:before_end_date].to_date + 1
    elsif params[:end_date]
      @before_end_date = params[:end_date].to_date - 1
      @end_date = params[:end_date].to_date
    else
      @before_end_date = start_date.next_month - 1
      @end_date = start_date.next_month
    end
    if params.present?
      if params["start_date(1i)"]
        @start_date = convert_date(params, :start_date)
      end
      if params["before_end_date(1i)"]
        @before_end_date = convert_date(params, :before_end_date)
        @end_date = @before_end_date + 1
      elsif params["end_date(1i)"]
        @end_date = convert_date(params, :end_date)
        @before_end_date = @end_date - 1
      else
        @before_end_date = start_date.next_month - 1
        @end_date = start_date.next_month
      end
      if params["vehicle_id"]
        @vehicle_id = params["vehicle_id"].to_i
      end
      if params["driver_id"]
        @driver_id = params["driver_id"].to_i
      end
      if params["trip_display"]
        @trip_display = params["trip_display"]
      end
    end
  end

  def persisted?
    false
  end

end

def bind(args)
  return ActiveRecord::Base.__send__(:sanitize_sql_for_conditions, args, '')
end

class ReportsController < ApplicationController

  def index
    @driver_query = Query.new :start_date => Date.today, :end_date => Date.today
    @trips_query = Query.new
    cab = Driver.new(:name=>"Cab")
    cab.id = -1
    all = Driver.new(:name=>"All")
    all.id = -2
    drivers = Driver.active.for_provider(current_provider).default_order.accessible_by(current_ability)
    @drivers =  [all] + drivers
    @drivers_with_cab =  [all, cab] + drivers
  end

  def vehicles_monthly
    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @start_date = @query.start_date
    @end_date = @query.end_date
    @vehicles = Vehicle.reportable.active.for_provider(current_provider).accessible_by(current_ability)
    @provider = current_provider

    @total_hours = {}
    @total_rides = {}
    @beginning_odometer = {}
    @ending_odometer = {}

    @vehicles.each do |vehicle|
      month_runs = Run.for_vehicle(vehicle.id).for_date_range(@start_date, @end_date)
      month_trips = Trip.for_vehicle(vehicle.id).for_date_range(@start_date, @end_date).completed

      @total_hours[vehicle] = month_runs.sum("actual_end_time - actual_start_time").to_i
      @total_rides[vehicle] = month_trips.reduce(0){|total,trip| total + trip.trip_count}

      @beginning_odometer[vehicle] = month_runs.minimum(:start_odometer) || -1
      @ending_odometer[vehicle] = month_runs.maximum(:end_odometer) || -1
    end
  end

  def service_summary
    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @start_date = @query.start_date
    @end_date = @query.end_date
    @monthly = Monthly.where(:start_date => @start_date, :provider_id=>current_provider_id).first
    @monthly = Monthly.new(:start_date=>@start_date, :provider_id=>current_provider_id) if @monthly.nil?
    @provider = current_provider

    if !can? :read, @monthly
      return redirect_to reports_path
    end

    #computes number of trips in and out of district by purpose
    counts_by_purpose = Trip.for_provider(current_provider_id).for_date_range(@start_date, @end_date)
        .includes(:customer, :pickup_address, :dropoff_address).completed

    by_purpose = {}
    TripPurpose.all.each do |purpose|
      by_purpose[purpose.name] = {'purpose' => purpose.name, 'in_district' => 0, 'out_of_district' => 0}
    end
    @total = {'in_district' => 0, 'out_of_district' => 0}

    counts_by_purpose.each do |row|
      purpose = row.trip_purpose
      next unless by_purpose.member?(purpose)

      if row.is_in_district?
        by_purpose[purpose]['in_district'] += row.trip_count
        @total['in_district'] += row.trip_count
      else
        by_purpose[purpose]['out_of_district'] += row.trip_count
        @total['out_of_district'] += row.trip_count
      end
    end

    @trips_by_purpose = []
    TripPurpose.all.each do |purpose|
      @trips_by_purpose << by_purpose[purpose.name]
    end

    #compute monthly totals
    runs = Run.for_provider(current_provider_id).for_date_range(@start_date, @end_date)

    mileage_runs = runs.select("vehicle_id, min(start_odometer) as min_odometer, max(end_odometer) as max_odometer").group("vehicle_id").with_odometer_readings
    @total_miles_driven = 0
    mileage_runs.each {|run| @total_miles_driven += (run.max_odometer.to_i - run.min_odometer.to_i) }

    @turndowns = Trip.turned_down.for_date_range(@start_date, @end_date).for_provider(current_provider_id).count
    @volunteer_driver_hours = hms_to_hours(runs.for_volunteer_driver.sum("actual_end_time - actual_start_time") || "0:00:00")
    @paid_driver_hours = hms_to_hours(runs.for_paid_driver.sum("actual_end_time - actual_start_time")  || "0:00:00")

    trip_customers = Trip.individual.select("DISTINCT customer_id").for_provider(current_provider_id).completed
    prior_customers_in_fiscal_year = trip_customers.for_date_range(fiscal_year_start_date(@start_date), @start_date).map {|x| x.customer_id}
    customers_this_period = trip_customers.for_date_range(@start_date, @end_date).map {|x| x.customer_id}
    @undup_riders = (customers_this_period - prior_customers_in_fiscal_year).size
  end

  def show_trips_for_verification
    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @trip_results = TripResult.pluck(:name, :code)

    unless @trips.present?
      @trips = Trip.for_provider(current_provider_id).for_date_range(@query.start_date,@query.end_date).
                includes(:customer,:run,:pickup_address,:dropoff_address)
      @trips = @trips.for_cab     if @query.trip_display == "Cab Trips"
      @trips = @trips.not_for_cab if @query.trip_display == "Not Cab Trips"
    end
  end

  def update_trips_for_verification
    @trips = Trip.update(params[:trips].keys, params[:trips].values).reject {|t| t.errors.empty?}
    if @trips.empty?
      redirect_to({:action => :show_trips_for_verification}, :notice => "Trips updated successfully" )
    else
      @trip_results = TripResult.pluck(:name, :code)
      render :action => :show_trips_for_verification
    end
  end

  def show_runs_for_verification
    query_params = params[:query] || {}
    @query = Query.new(query_params)

    @drivers  = Driver.active.where(:provider_id=>current_provider_id).default_order
    @vehicles = Vehicle.active.where(:provider_id=>current_provider_id)
    @runs = Run.for_provider(current_provider_id).for_date_range(@query.start_date,@query.end_date) unless @runs.present?
  end

  def update_runs_for_verification
    @runs = Run.update(params[:runs].keys, params[:runs].values).reject {|t| t.errors.empty?}
    if @runs.empty?
      redirect_to({:action => :show_runs_for_verification}, :notice => "Runs updated successfully" )
    else
      @drivers  = Driver.active.where(:provider_id=>current_provider_id).default_order
      @vehicles = Vehicle.active.where(:provider_id=>current_provider_id)
      render :action => :show_runs_for_verification
    end
  end

  def donations
    query_params = params[:query] || {}
    @query = Query.new(query_params)

    @donations_by_customer = {}
    @total = 0
    for trip in Trip.for_provider(current_provider_id).for_date_range(@query.start_date, @query.end_date).where(["donation > 0"]).order(:pickup_time)
      customer = trip.customer
      if ! @donations_by_customer.member? customer
        @donations_by_customer[customer] = trip.donation
      else
        @donations_by_customer[customer] += trip.donation
      end
      @total += trip.donation
    end
    @customers = @donations_by_customer.keys.sort_by {|customer| [customer.last_name, customer.first_name] }
  end

  def cab
    query_params = params[:query] || {}
    @query = Query.new(query_params)

    @trips = Trip.for_provider(current_provider_id).for_date_range(@query.start_date, @query.end_date).for_cab.completed.order(:pickup_time)
  end

  def age_and_ethnicity
    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @start_date = @query.start_date
    @end_date = @query.end_date

    #we need new riders this month, where new means "first time this fy"
    #so, for each trip this month, find the customer, then find out whether
    # there was a previous trip for this customer this fy

    trip_customers = Trip.individual.select("DISTINCT customer_id").for_provider(current_provider_id).completed
    prior_customers_in_fiscal_year = trip_customers.for_date_range(fiscal_year_start_date(@start_date), @start_date).map {|x| x.customer_id}
    customers_this_period = trip_customers.for_date_range(@start_date, @end_date).map {|x| x.customer_id}

    new_customers = Customer.where(:id => (customers_this_period - prior_customers_in_fiscal_year))
    earlier_customers = Customer.where(:id => prior_customers_in_fiscal_year)

    @this_month_unknown_age = 0
    @this_month_sixty_plus = 0
    @this_month_less_than_sixty = 0

    @this_year_unknown_age = 0
    @this_year_sixty_plus = 0
    @this_year_less_than_sixty = 0

    @counts_by_ethnicity = {}
    @provider = current_provider

    #first, handle the customers from this month
    for customer in new_customers
      age = customer.age_in_years
      if age.nil?
        @this_month_unknown_age += 1
        @this_year_unknown_age += 1
      elsif age > 60
        @this_month_sixty_plus += 1
        @this_year_sixty_plus += 1
      else
        @this_month_less_than_sixty += 1
        @this_year_less_than_sixty += 1
      end

      ethnicity = customer.ethnicity || "Unspecified"
      if ! @counts_by_ethnicity.member? ethnicity
        @counts_by_ethnicity[ethnicity] = {'month' => 0, 'year' => 0}
      end
      @counts_by_ethnicity[ethnicity]['month'] += 1
      @counts_by_ethnicity[ethnicity]['year'] += 1
    end

    #now the customers who appear earlier in the year
    for customer in earlier_customers
      age = customer.age_in_years
      if age.nil?
        @this_year_unknown_age += 1
      elsif age > 60
        @this_year_sixty_plus += 1
      else
        @this_year_less_than_sixty += 1
      end

      ethnicity = customer.ethnicity || "Unspecified"
      if ! @counts_by_ethnicity.member? ethnicity
        @counts_by_ethnicity[ethnicity] = {'month' => 0, 'year' => 0}
      end
      @counts_by_ethnicity[ethnicity]['year'] += 1
    end

  end

  def daily_manifest
    authorize! :read, Trip

    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @date = @query.start_date

    cab = Driver.new(:name=>'Cab') #dummy driver for cab trips

    trips = Trip.scheduled.for_provider(current_provider_id).for_date(@date).includes(:pickup_address,:dropoff_address,:customer,:mobility,{:run => :driver}).order(:pickup_time)
    if @query.driver_id == -2 # All
      # No additional filtering
    elsif @query.driver_id == -1 # Cab
      trips = trips.for_cab
    else
      authorize! :read, Driver.find(@query.driver_id)
      trips = trips.for_driver(@query.driver_id)
    end
    @trips = trips.group_by {|trip| trip.run ? trip.run.driver : cab }
  end

  def daily_manifest_with_cab
    prep_with_cab
    render "daily_manifest"
  end

  def daily_manifest_by_half_hour
    daily_manifest #same data, operated on differently in the view
    @start_hour = 7
    @end_hour = 17
  end

  def daily_manifest_by_half_hour_with_cab
    prep_with_cab
    @start_hour = 7
    @end_hour = 17
    render "daily_manifest_by_half_hour"
  end

  def daily_trips
    authorize! :read, Trip

    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @date = @query.start_date

    @trips = Trip.for_provider(current_provider_id).for_date(@date).includes(:pickup_address,:dropoff_address,:customer,:mobility,{:run => :driver}).order(:pickup_time)
  end

  def export_trips_in_range
    authorize! :read, Trip

    @query = Query.new(params[:query])
    date_range = @query.start_date..@query.end_date
    columns = Trip.column_names.map{|c| "\"#{Trip.table_name}\".\"#{c}\" as \"#{Trip.table_name}.#{c}\""} + Customer.column_names.map{|c| "\"#{Customer.table_name}\".\"#{c}\" as \"#{Customer.table_name}.#{c}\""}
    sql = Trip.select(columns.join(',')).joins(:customer).where(:pickup_time => date_range).order(:pickup_time).to_sql
    trips = ActiveRecord::Base.connection.select_all(sql)
    csv_string = CSV.generate do |csv|
      csv << columns.collect{|c| c.split(' as ').last.strip.gsub("\"", "") }
      unless trips.empty?
        trips.each do |t|
          csv << t.values
        end
      end
    end

    attrs = {
      filename:    "export_trips_in_range-#{@query.start_date.strftime('%b %d %Y').downcase.parameterize}-#{@query.before_end_date.strftime('%b %d %Y').downcase.parameterize}.csv",
      type:        Mime::CSV,
      disposition: "attachment",
      streaming:   "true",
      buffer_size: 4096
    }
    send_data(csv_string, attrs)
  end

  def customer_receiving_trips_in_range
    authorize! :read, Trip

    @query = Query.new(params[:query])
    date_range = @query.start_date..@query.end_date
    @customers = Customer.joins(:trips).where('trips.pickup_time' => date_range).includes(:trips).uniq()
  end

  def cctc_summary_report
    authorize! :read, Trip

    Trip.define_singleton_method(:for_customers_under_60) do |compare_date|
      self.joins(:customer).where('"customers"."birth_date" >= ?', compare_date.to_date - 60.years)
    end

    Trip.define_singleton_method(:for_customers_over_60) do |compare_date|
      self.joins(:customer).where('"customers"."birth_date" < ?', compare_date.to_date - 60.years)
    end

    Trip.define_singleton_method(:for_ada_eligible_customers) do
      self.joins(:customer).where('"customers"."ada_eligible" = ?', true)
    end

    Trip.define_singleton_method(:unique_customer_count) do
      self.count('DISTINCT "customer_id"')
    end

    Trip.define_singleton_method(:total_ride_count) do
      # Factors in return trips
      self.all.collect(&:trip_count).sum
    end

    Trip.define_singleton_method(:total_mileage) do
      # Factors in return trips
      self.sum(:mileage)
    end

    Run.define_singleton_method(:for_trips_collection) do |trips_collection|
      self.where(id: trips_collection.collect(&:run_id).uniq.compact)
    end

    Run.define_singleton_method(:unique_driver_count) do
      self.count('DISTINCT "driver_id"')
    end

    Run.define_singleton_method(:total_driver_hours) do
      hours = []
      self.all.each do |run|
        if run.actual_start_time.present? && run.actual_end_time.present?
          time = (run.actual_end_time.to_time - run.actual_start_time.to_time) / 60
          time -= run.unpaid_driver_break_time if run.unpaid_driver_break_time.present?
          hours << (time / 60).round(2)
        end
      end
      hours.sum.to_f
    end

    Run.define_singleton_method(:total_mileage) do
      # Factors in return trips
      miles = []
      self.all.each do |run|
        if run.start_odometer.present? && run.end_odometer.present?
          miles << run.end_odometer - run.start_odometer
        end
      end
      miles.sum.to_i
    end

    FundingSource.define_singleton_method(:pick_id_by_name) do |name|
      self.where(name: name).first.try(:id).to_i
    end

    @query = Query.new(params[:query] || {})
    @start_date = @query.start_date
    @end_date = @query.end_date

    @provider = Provider.find(current_provider_id)
    new_customer_ids = ActiveRecord::Base.connection.select_values(Customer.select('DISTINCT "customers"."id"').joins("LEFT JOIN \"trips\" \"previous_months_trips\" ON \"customers\".\"id\" = \"previous_months_trips\".\"customer_id\" AND (#{ActiveRecord::Base.send(:sanitize_sql_array, ['"previous_months_trips"."pickup_time" < ?', @start_date.to_datetime.in_time_zone.utc])})", "LEFT JOIN \"trips\" \"current_months_trips\" ON \"customers\".\"id\" = \"current_months_trips\".\"customer_id\" AND (#{ActiveRecord::Base.send(:sanitize_sql_array, ['"current_months_trips"."pickup_time" >= ? AND "current_months_trips"."pickup_time" < ?', @start_date.to_datetime.in_time_zone.utc, @end_date.to_datetime.in_time_zone.utc])})").group('"customers"."id"').having('COUNT("previous_months_trips"."id") = 0 AND COUNT("current_months_trips"."id") > 0').except(:order).to_sql)
    new_driver_ids = ActiveRecord::Base.connection.select_values(Driver.select('DISTINCT "drivers"."id"').joins("LEFT JOIN \"runs\" \"previous_months_runs\" ON \"drivers\".\"id\" = \"previous_months_runs\".\"driver_id\" AND (#{ActiveRecord::Base.send(:sanitize_sql_array, ['"previous_months_runs"."date" < ?', @start_date.to_datetime.in_time_zone.utc])})", "LEFT JOIN \"runs\" \"current_months_runs\" ON \"drivers\".\"id\" = \"current_months_runs\".\"driver_id\" AND (#{ActiveRecord::Base.send(:sanitize_sql_array, ['"current_months_runs"."date" >= ? AND "current_months_runs"."date" < ?', @start_date.to_datetime.in_time_zone.utc, @end_date.to_datetime.in_time_zone.utc])})").group('"drivers"."id"').having('COUNT("previous_months_runs"."id") = 0 AND COUNT("current_months_runs"."id") > 0').except(:order).to_sql)
    monthly_base_query = Monthly.where(provider_id: @provider.id, start_date: @start_date..@end_date)

    trip_queries = {
      in_range: {
        all: Trip.for_provider(@provider.id).for_date_range(@start_date, @end_date),
        stf: {}
      },
      ytd: {
        all: Trip.for_provider(@provider.id).for_date_range(Date.new(@start_date.year, 1, 1), @end_date)
      }
    }
    trip_queries[:in_range][:rc]  = trip_queries[:in_range][:all].where(funding_source_id: FundingSource.pick_id_by_name("Ride Connection"))
    trip_queries[:in_range][:stf][:all]  = trip_queries[:in_range][:all].where(funding_source_id: FundingSource.pick_id_by_name("STF"))
    trip_queries[:in_range][:stf][:van]  = trip_queries[:in_range][:stf][:all].not_for_cab
    trip_queries[:in_range][:stf][:taxi] = trip_queries[:in_range][:stf][:all].for_cab
    trip_queries[:ytd][:rc]  = trip_queries[:ytd][:all].where(funding_source_id: FundingSource.pick_id_by_name("Ride Connection"))
    trip_queries[:ytd][:stf] = trip_queries[:ytd][:all].where(funding_source_id: FundingSource.pick_id_by_name("STF"))

    @report = {
      total_miles: {
        stf: {
          van_bus: Run.for_trips_collection(trip_queries[:in_range][:stf][:van]).total_mileage,
          taxi:    trip_queries[:in_range][:stf][:taxi].total_mileage,
        },
        rc: Run.for_trips_collection(trip_queries[:in_range][:rc]).total_mileage,
      },
      rider_information: {
        riders_new_this_month: {
          over_60: {
            rc:  trip_queries[:in_range][:rc].for_customers_over_60(@end_date).where(customer_id: new_customer_ids).unique_customer_count,
            stf: trip_queries[:in_range][:stf][:all].for_customers_over_60(@end_date).where(customer_id: new_customer_ids).unique_customer_count,
          },
          under_60: {
            rc:  trip_queries[:in_range][:rc].for_customers_under_60(@end_date).where(customer_id: new_customer_ids).unique_customer_count,
            stf: trip_queries[:in_range][:stf][:all].for_customers_under_60(@end_date).where(customer_id: new_customer_ids).unique_customer_count,
          },
          ada_eligible: {
            over_60:  trip_queries[:in_range][:all].where(funding_source_id: [FundingSource.pick_id_by_name("Ride Connection"), FundingSource.pick_id_by_name("STF")]).for_customers_over_60(@end_date).where(customer_id: new_customer_ids).unique_customer_count,
            under_60: trip_queries[:in_range][:all].where(funding_source_id: [FundingSource.pick_id_by_name("Ride Connection"), FundingSource.pick_id_by_name("STF")]).for_customers_under_60(@end_date).where(customer_id: new_customer_ids).unique_customer_count,
          },
        },
        riders_ytd: {
          over_60: {
            rc:  trip_queries[:ytd][:rc].for_customers_over_60(@end_date).unique_customer_count,
            stf: trip_queries[:ytd][:stf].for_customers_over_60(@end_date).unique_customer_count,
          },
          under_60: {
            rc:  trip_queries[:ytd][:rc].for_customers_under_60(@end_date).unique_customer_count,
            stf: trip_queries[:ytd][:stf].for_customers_under_60(@end_date).unique_customer_count,
          },
          ada_eligible: {
            over_60:  trip_queries[:ytd][:all].where(funding_source_id: [FundingSource.pick_id_by_name("Ride Connection"), FundingSource.pick_id_by_name("STF")]).for_customers_over_60(@end_date).where(customer_id: new_customer_ids).unique_customer_count,
            under_60: trip_queries[:ytd][:all].where(funding_source_id: [FundingSource.pick_id_by_name("Ride Connection"), FundingSource.pick_id_by_name("STF")]).for_customers_under_60(@end_date).where(customer_id: new_customer_ids).unique_customer_count,
          },
        },
      },
      driver_information: {
        number_of_driver_hours: {
          paid: {
            rc:  Run.for_paid_driver.for_trips_collection(trip_queries[:in_range][:rc]).total_driver_hours,
            stf: Run.for_paid_driver.for_trips_collection(trip_queries[:in_range][:stf][:all]).total_driver_hours,
          },
          volunteer: {
            rc:  Run.for_volunteer_driver.for_trips_collection(trip_queries[:in_range][:rc]).total_driver_hours,
            stf: Run.for_volunteer_driver.for_trips_collection(trip_queries[:in_range][:stf][:all]).total_driver_hours,
          },
        },
        number_of_active_drivers: {
          paid: {
            rc:  Run.for_paid_driver.for_trips_collection(trip_queries[:in_range][:rc]).unique_driver_count,
            stf: Run.for_paid_driver.for_trips_collection(trip_queries[:in_range][:stf][:all]).unique_driver_count,
          },
          volunteer: {
            rc:  Run.for_volunteer_driver.for_trips_collection(trip_queries[:in_range][:rc]).unique_driver_count,
            stf: Run.for_volunteer_driver.for_trips_collection(trip_queries[:in_range][:stf][:all]).unique_driver_count,
          },
        },
        drivers_new_this_month: {
          paid: {
            rc:  Run.for_paid_driver.for_trips_collection(trip_queries[:in_range][:rc]).where(driver_id: new_driver_ids).unique_driver_count,
            stf: Run.for_paid_driver.for_trips_collection(trip_queries[:in_range][:stf][:all]).where(driver_id: new_driver_ids).unique_driver_count,
          },
          volunteer: {
            rc:  Run.for_volunteer_driver.for_trips_collection(trip_queries[:in_range][:rc]).where(driver_id: new_driver_ids).unique_driver_count,
            stf: Run.for_volunteer_driver.for_trips_collection(trip_queries[:in_range][:stf][:all]).where(driver_id: new_driver_ids).unique_driver_count,
          },
        },
        escort_hours: {
          rc:  monthly_base_query.where(funding_source_id: FundingSource.pick_id_by_name("Ride Connection")).first.try(:volunteer_escort_hours),
          stf:  monthly_base_query.where(funding_source_id: FundingSource.pick_id_by_name("STF")).first.try(:volunteer_escort_hours),
        },
        administrative_hours: {
          rc:  monthly_base_query.where(funding_source_id: FundingSource.pick_id_by_name("Ride Connection")).first.try(:volunteer_admin_hours),
          stf:  monthly_base_query.where(funding_source_id: FundingSource.pick_id_by_name("STF")).first.try(:volunteer_admin_hours),
        },
      },
      rides_not_given: {
        turndowns: {
          rc: trip_queries[:in_range][:rc].by_result('TD').count,
          stf: trip_queries[:in_range][:stf][:all].by_result('TD').count,
        },
        cancels: {
          rc: trip_queries[:in_range][:rc].by_result('CANC').count,
          stf: trip_queries[:in_range][:stf][:all].by_result('CANC').count,
        },
        no_shows: {
          rc: trip_queries[:in_range][:rc].by_result('NS').count,
          stf: trip_queries[:in_range][:stf][:all].by_result('NS').count,
        },
      },
      rider_donations: {
        rc: trip_queries[:in_range][:rc].sum(:donation),
        stf: trip_queries[:in_range][:stf][:all].sum(:donation),
      },
      trip_purposes: {trips: [], total_rides: {}, reimbursements_due: {}}, # We will loop over and add these later
      new_rider_ethinic_heritage: {ethnicities: []}, # We will loop over and add the rest of these later
    }

    TripPurpose.order(:name).each do |tp|
      trip = {
        name: tp.name,
        oaa3b: trip_queries[:in_range][:all].where(funding_source_id: FundingSource.pick_id_by_name("OAA")).where(trip_purpose: tp).total_ride_count,
        rc: trip_queries[:in_range][:rc].where(trip_purpose: tp).total_ride_count,
        trimet: trip_queries[:in_range][:all].where(funding_source_id: FundingSource.pick_id_by_name("TriMet Non-Medical")).where(trip_purpose: tp).total_ride_count,
        stf_van: trip_queries[:in_range][:stf][:van].where(trip_purpose: tp).total_ride_count,
        stf_taxi: {
          all: {
            count: trip_queries[:in_range][:stf][:taxi].where(trip_purpose: tp).total_ride_count,
            mileage: trip_queries[:in_range][:stf][:taxi].where(trip_purpose: tp).total_mileage
          },
          wheelchair: {
            count: trip_queries[:in_range][:stf][:taxi].where(trip_purpose: tp).by_service_level("Wheelchair").total_ride_count,
            mileage: trip_queries[:in_range][:stf][:taxi].where(trip_purpose: tp).by_service_level("Wheelchair").total_mileage
          },
          ambulatory: {
            count: trip_queries[:in_range][:stf][:taxi].where(trip_purpose: tp).by_service_level("Ambulatory").total_ride_count,
            mileage: trip_queries[:in_range][:stf][:taxi].where(trip_purpose: tp).by_service_level("Ambulatory").total_mileage
          },
        },
        unreimbursed: trip_queries[:in_range][:all].where(funding_source_id: FundingSource.pick_id_by_name("Unreimbursed")).where(trip_purpose: tp).total_ride_count,
      }
      trip[:total_rides] = trip[:oaa3b] +
        trip[:rc] +
        trip[:trimet] +
        trip[:stf_van] +
        trip[:stf_taxi][:all][:count] +
        trip[:unreimbursed]
      @report[:trip_purposes][:trips] << trip
    end
    @report[:trip_purposes][:total_rides] = {
      oaa3b: @report[:trip_purposes][:trips].collect{|t| t[:oaa3b]}.sum,
      rc: @report[:trip_purposes][:trips].collect{|t| t[:rc]}.sum,
      trimet: @report[:trip_purposes][:trips].collect{|t| t[:trimet]}.sum,
      stf_van: @report[:trip_purposes][:trips].collect{|t| t[:stf_van]}.sum,
      stf_taxi: @report[:trip_purposes][:trips].collect{|t| t[:stf_taxi][:all][:count]}.sum,
      unreimbursed: @report[:trip_purposes][:trips].collect{|t| t[:unreimbursed]}.sum,
    }
    @report[:trip_purposes][:reimbursements_due] = {
      oaa3b: @report[:trip_purposes][:total_rides][:oaa3b] * @provider.oaa3b_per_ride_reimbursement_rate.to_f,
      rc: @report[:trip_purposes][:total_rides][:rc] * @provider.ride_connection_per_ride_reimbursement_rate.to_f,
      trimet: @report[:trip_purposes][:total_rides][:trimet] * @provider.trimet_per_ride_reimbursement_rate.to_f,
      stf_van: @report[:trip_purposes][:total_rides][:stf_van] * @provider.stf_van_per_ride_reimbursement_rate.to_f,
      stf_taxi: (
        (@report[:trip_purposes][:trips].collect{|t| t[:stf_taxi][:wheelchair][:count]}.sum * @provider.stf_taxi_per_ride_wheelchair_load_fee.to_f) +
        (@report[:trip_purposes][:trips].collect{|t| t[:stf_taxi][:wheelchair][:mileage]}.sum * @provider.stf_taxi_per_mile_wheelchair_reimbursement_rate.to_f) +
        (@report[:trip_purposes][:trips].collect{|t| t[:stf_taxi][:ambulatory][:count]}.sum * @provider.stf_taxi_per_ride_ambulatory_load_fee.to_f) +
        (@report[:trip_purposes][:trips].collect{|t| t[:stf_taxi][:ambulatory][:mileage]}.sum * @provider.stf_taxi_per_mile_ambulatory_reimbursement_rate.to_f) +
        (@report[:trip_purposes][:total_rides][:stf_taxi] * @provider.stf_taxi_per_ride_administrative_fee.to_f)
      ),
    }

    non_other_ethnicities = []
    @provider.ethnicities.each do |e|
      next if e.name == "Other"
      @report[:new_rider_ethinic_heritage][:ethnicities] << {
        name: e.name,
        trips: {
          rc: trip_queries[:in_range][:rc].joins(:customer).where(customers: {ethnicity: e.name}).unique_customer_count,
          stf: trip_queries[:in_range][:stf][:all].joins(:customer).where(customers: {ethnicity: e.name}).unique_customer_count,
        },
      }
      non_other_ethnicities << e.name
    end
    @report[:new_rider_ethinic_heritage][:ethnicities] << {
      name: "Other",
      trips: {
        rc: trip_queries[:in_range][:rc].joins(:customer).where('"customers"."ethnicity" NOT IN (?)', non_other_ethnicities).unique_customer_count,
        stf: trip_queries[:in_range][:stf][:all].joins(:customer).where('"customers"."ethnicity" NOT IN (?)', non_other_ethnicities).unique_customer_count,
      },
    }
  end

  private

  def prep_with_cab
    authorize! :read, Trip

    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @date = @query.start_date

    trips = Trip.scheduled.for_provider(current_provider_id).for_date(@date).includes(:pickup_address,:dropoff_address,:customer,:mobility,{:run => :driver}).order(:pickup_time)
    @cab_trips = Trip.for_cab.scheduled.for_provider(current_provider_id).for_date(@date).includes(:pickup_address,:dropoff_address,:customer,:mobility,{:run => :driver}).order(:pickup_time)

    if @query.driver_id == -2 # All
      trips = trips.not_for_cab
    else
      authorize! :read, Driver.find(@query.driver_id)
      trips = trips.for_driver(@query.driver_id)
    end
    @trips = trips.group_by {|trip| trip.run.try(:driver) }
  end

  def hms_to_hours(hms)
    #argument is a string of the form hours:minutes:seconds.  We would like
    #a float of hours
    return 0 if hms == 0 || hms.blank?

    hours, minutes, seconds = hms.split(":").map &:to_i
    hours ||= 0
    minutes ||= 0
    seconds ||= 0
    return hours + minutes / 60.0 + seconds / 3600.0
  end

  def fiscal_year_start_date(date)
    year = (date.month < 7 ? date.year - 1 : date.year)
    Date.new(year, 7, 1)
  end
end
