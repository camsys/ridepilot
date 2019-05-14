require 'csv'

class Query
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :start_date
  attr_accessor :before_end_date
  attr_accessor :end_date
  attr_accessor :vehicle_id
  attr_accessor :driver_id
  attr_accessor :run_ids
  attr_accessor :run_id
  attr_accessor :customer_id
  attr_accessor :mobility_id
  attr_accessor :trip_display
  attr_accessor :address_group_id
  attr_accessor :ntd_year
  attr_accessor :ntd_month
  attr_accessor :run_inspection_type
  attr_accessor :report_format
  attr_accessor :report_type

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
        @before_end_date = start_date.next_month - 1 if !@before_end_date
        @end_date = start_date.next_month if !@end_date
      end
      if params["vehicle_id"]
        @vehicle_id = params["vehicle_id"].to_i unless params["vehicle_id"].blank?
      end
      if params["driver_id"]
        @driver_id = params["driver_id"].to_i unless params["driver_id"].blank?
      end

      if params["run_id"]
        @run_ids = [params["run_id"].to_i] unless params["run_id"].blank?
      end

      if params["run_ids"]
        @run_ids = params["run_ids"].split(',') unless params["run_ids"].blank?
      end
      if params["customer_id"]
        @customer_id = params["customer_id"].to_i unless params["customer_id"].blank?
      end
      if params["mobility_id"]
        @mobility_id = params["mobility_id"].to_i unless params["mobility_id"].blank?
      end
      if params["address_group_id"]
        @address_group_id = params["address_group_id"]
      end
      if params["ntd_year"]
        @ntd_year = params["ntd_year"].to_i unless params["ntd_year"].blank?
      end
      if params["ntd_month"]
        @ntd_month = params["ntd_month"].to_i unless params["ntd_month"].blank?
      end
      if params["run_inspection_type"]
        @run_inspection_type = params["run_inspection_type"]
      end
      if params["report_format"]
        @report_format = params["report_format"]
      end
      if params["report_type"]
        @report_type = params["report_type"]
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
  return ApplicationRecord.__send__(:sanitize_sql_for_conditions, args, '')
end

class ReportsController < ApplicationController
  include Reporting::ReportHelper

  before_action :set_reports, except: [:get_run_list, :show_save_form]
  before_action :set_custom_report, except: [:get_run_list, :show_save_form, :save_as, :saved_report, :show_saved_report, :delete_saved_report]

  def show
    @driver_query = Query.new :start_date => Date.today, :end_date => Date.today
    @trips_query = Query.new
    cab = Driver.new(:name=>"Cab")
    cab.id = -1
    all = Driver.new(:name=>"All")
    all.id = -2
    drivers = Driver.active.for_provider(current_provider).default_order.accessible_by(current_ability)
    @drivers =  [all] + drivers
    @drivers_with_cab =  [all, cab] + drivers

    redirect_to action: @custom_report.name if @custom_report.redirect_to_results
  end

  ######################################################################################
  # V1 reports
  # HTML report only
  ######################################################################################

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

  def monthlies
    @monthlies = Monthly.order(:start_date)
  end

  def service_summary
    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @start_date = @query.start_date
    @end_date = @query.end_date
    if @end_date && @start_date && @end_date < @start_date
      flash.now[:alert] = TranslationEngine.translate_text(:service_summary_end_date_earlier_than_start_date)
    end
    @monthly = Monthly.where(:start_date => @start_date, :provider_id=>current_provider_id).first
    @monthly = Monthly.new(:start_date=>@start_date, :provider_id=>current_provider_id) if @monthly.nil?
    @provider = current_provider

    if !can? :read, @monthly
      return redirect_to reporting.reports_path
    end

    #computes number of trips in and out of district by purpose
    counts_by_purpose = Trip.for_provider(current_provider_id).for_date_range(@start_date, @end_date)
        .includes(:customer, :pickup_address, :dropoff_address).completed

    by_purpose = {}
    TripPurpose.by_provider(current_provider).each do |purpose|
      by_purpose[purpose.name] = {'purpose' => purpose.name, 'in_district' => 0, 'out_of_district' => 0}
    end
    @total = {'in_district' => 0, 'out_of_district' => 0}

    counts_by_purpose.each do |row|
      purpose = row.trip_purpose.try(:name)
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
    TripPurpose.by_provider(current_provider).all.each do |purpose|
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
    @trip_results = TripResult.by_provider(current_provider).pluck(:name, :id)

    unless @trips.present?
      @trips = Trip.for_provider(current_provider_id).for_date_range(@query.start_date, @query.end_date).
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
      @trip_results = TripResult.by_provider(current_provider).pluck(:name, :id)
      render :action => :show_trips_for_verification
    end
  end

  def show_runs_for_verification
    query_params = params[:query] || {}
    @query = Query.new(query_params)

    @drivers  = Driver.active.where(:provider_id=>current_provider_id).default_order
    @vehicles = Vehicle.active.where(:provider_id=>current_provider_id)
    @runs = Run.for_provider(current_provider_id).for_date_range(@query.start_date, @query.end_date) unless @runs.present?
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

    donations = Donation.for_date_range(@query.start_date, @query.end_date)
    @total = donations.sum(:amount)
    @customers = Customer.where(id: donations.pluck(:customer_id).uniq)
    @donations_by_customer = donations.group(:customer_id).sum(:amount)
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

  def driver_manifest
    authorize! :read, Trip

    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @date = @query.start_date

    @runs = Run.for_provider(current_provider_id).for_date(@date).joins(:trips)
      .includes(trips: [:pickup_address, :dropoff_address, :customer, :mobility])
    run_ids = @runs.pluck(:id).uniq
    
    @runs = @runs.order(:scheduled_start_time).distinct
    if @query.driver_id != -2 # All
      @runs = @runs.for_driver(@query.driver_id)
    end

    @trips_by_customer = Trip.where("cab = TRUE or run_id in (?)", run_ids).for_provider(current_provider_id).for_date(@date).group_by(&:customer)
  end

  def daily_manifest
    authorize! :read, Trip

    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @date = @query.start_date

    cab = Driver.new(:name=>'Cab') #dummy driver for cab trips

    trips = Trip.empty_or_completed.for_provider(current_provider_id).for_date(@date).includes(:pickup_address, :dropoff_address, :customer, :mobility, {run: :driver}).order(:pickup_time)
    if @query.driver_id == -2 # All
      # No additional filtering
    elsif @query.driver_id == -1 # Cab
      trips = trips.for_cab
    else
      authorize! :read, Driver.find(@query.driver_id)
      trips = trips.for_driver(@query.driver_id)
    end
    @trips = trips.group_by {|trip| trip.run ? trip.run.driver : cab }
    @trips_by_customer = trips.group_by(&:customer)
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
    @trips_by_customer = @trips.group_by(&:customer)
  end

  def export_trips_in_range
    authorize! :read, Trip

    @query = Query.new(params[:query])
    date_range = @query.start_date..@query.end_date
    columns = Trip.column_names.map{|c| "\"#{Trip.table_name}\".\"#{c}\" as \"#{Trip.table_name}.#{c}\""} + Customer.column_names.map{|c| "\"#{Customer.table_name}\".\"#{c}\" as \"#{Customer.table_name}.#{c}\""}
    sql = Trip.select(columns.join(',')).joins(:customer).where(:pickup_time => date_range).order(:pickup_time).to_sql
    trips = ApplicationRecord.connection.select_all(sql)
    csv_string = CSV.generate do |csv|
      csv << columns.collect{|c| c.split(' as ').last.strip.gsub("\"", "") }
      unless trips.empty?
        trips.each do |t|
          csv << t.values
        end
      end
    end

    attrs = {
      filename:    "#{Time.current.strftime('%Y%m%d%H%M')}_export_trips_in_range-#{@query.start_date.strftime('%b %d %Y').downcase.parameterize}-#{@query.before_end_date.strftime('%b %d %Y').downcase.parameterize}.csv",
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
    @customers = Customer.unscoped.joins(:trips).where('trips.pickup_time' => date_range).includes(:trips).uniq()
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
    new_customer_ids = ApplicationRecord.connection.select_values(Customer.select('DISTINCT "customers"."id"').joins("LEFT JOIN \"trips\" \"previous_months_trips\" ON \"customers\".\"id\" = \"previous_months_trips\".\"customer_id\" AND (#{ApplicationRecord.send(:sanitize_sql_array, ['"previous_months_trips"."pickup_time" < ?', @start_date.to_datetime.in_time_zone.utc])})", "LEFT JOIN \"trips\" \"current_months_trips\" ON \"customers\".\"id\" = \"current_months_trips\".\"customer_id\" AND (#{ApplicationRecord.send(:sanitize_sql_array, ['"current_months_trips"."pickup_time" >= ? AND "current_months_trips"."pickup_time" < ?', @start_date.to_datetime.in_time_zone.utc, @end_date.to_datetime.in_time_zone.utc])})").group('"customers"."id"').having('COUNT("previous_months_trips"."id") = 0 AND COUNT("current_months_trips"."id") > 0').except(:order).to_sql)
    new_driver_ids = ApplicationRecord.connection.select_values(Driver.select('DISTINCT "drivers"."id"').joins("LEFT JOIN \"runs\" \"previous_months_runs\" ON \"drivers\".\"id\" = \"previous_months_runs\".\"driver_id\" AND (#{ApplicationRecord.send(:sanitize_sql_array, ['"previous_months_runs"."date" < ?', @start_date.to_datetime.in_time_zone.utc])})", "LEFT JOIN \"runs\" \"current_months_runs\" ON \"drivers\".\"id\" = \"current_months_runs\".\"driver_id\" AND (#{ApplicationRecord.send(:sanitize_sql_array, ['"current_months_runs"."date" >= ? AND "current_months_runs"."date" < ?', @start_date.to_datetime.in_time_zone.utc, @end_date.to_datetime.in_time_zone.utc])})").group('"drivers"."id"').having('COUNT("previous_months_runs"."id") = 0 AND COUNT("current_months_runs"."id") > 0').except(:order).to_sql)
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
        rc: trip_queries[:in_range][:rc].joins(:donation).sum("donations.amount"),
        stf: trip_queries[:in_range][:stf][:all].joins(:donation).sum("donations.amount"),
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
    Ethnicity.by_provider(@provider).each do |e|
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

  ######################################################################################
  # V2 reports
  # supports PDF & CSV
  ######################################################################################

  def provider_common_location_report
    query_params = params[:query] || {}
    @query = Query.new(query_params)
    
    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      @addresses = current_provider.addresses.sort_by_name
      unless @query.address_group_id.blank?
        address_group = AddressGroup.find_by_id @query.address_group_id
        @addresses = @addresses.where(address_group_id: @query.address_group_id)
        @report_params << ["Address Type", address_group.try(:name)]
      end
    end

    apply_v2_response
  end

  def missing_data_report
    query_params = params[:query] || {start_date: Date.today.prev_month + 1, end_date: Date.today + 1}
    @query = Query.new(query_params)
    
    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      @report_params << ["Date Range", "#{@query.start_date.strftime('%m/%d/%Y')} - #{@query.before_end_date.strftime('%m/%d/%Y')}"]
      @runs = Run.for_provider(current_provider_id).for_date_range(@query.start_date, @query.end_date).incomplete.order(:date, "lower(name)")
      @data_by_date = {}
      @runs.each do |run|
        @data_by_date[run.date] = [] unless @data_by_date.has_key?(run.date)
        day_data = @data_by_date[run.date]
        day_data << [run.name, run.id, run.incomplete_reason.join("; ")]
      end

      @run_dates = @data_by_date.keys.sort
    end

    apply_v2_response
  end

  def ineligible_customer_status_report
    query_params = params[:query] || {}
    @query = Query.new(query_params)

    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      @customers = Customer.for_provider(current_provider_id).order("lower(last_name)", "lower(first_name)")
      if query_params[:report_type] == 'summary'
        @report_params << ["Inactive Type", "Temporary"]
        # only temp_inactive for summary report
        @customers = @customers.temporarily_inactive_for_date(Date.today)
      else
        @report_params << ["Inactive Type", "Permanent and Temporary"]
        # temp_inactive and perm_inactive for detailed report
        @customers = @customers.inactive_for_date(Date.today)
      end
    end

    apply_v2_response
  end

  def inactive_driver_status_report
    query_params = params[:query] || {}
    @query = Query.new(query_params)

    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      @drivers = Driver.for_provider(current_provider_id).default_order
      if query_params[:report_type] == 'perm_inacitve'
        @is_perm_inactive_report = true
        @report_params << ["Inactive Type", "Permanent"]
        # only perm_inactive
        @drivers = @drivers.permanent_inactive
      else
        @report_params << ["Inactive Type", "Temporary"]
        # temp_inactive for detailed report
        @drivers = @drivers.active.inactive_for_date(Date.today)
      end
    end

    apply_v2_response
  end

  def customer_donation_report
    query_params = params[:query] || {start_date: Date.today.prev_month + 1, end_date: Date.today + 1}
    @query = Query.new(query_params)

    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      @report_params << ["Date Range", "#{@query.start_date.strftime('%m/%d/%Y')} - #{@query.before_end_date.strftime('%m/%d/%Y')}"]

      @customers = Customer.active_for_date(Date.today).for_provider(current_provider_id)
      customer_ids = @customers.pluck(:id)
      donations = Donation.for_date_range(@query.start_date, @query.end_date).where(customer_id: customer_ids)
      donations_by_customer = donations.group(:customer_id).sum(:amount)
      @report_data = {}
      donations.order(:customer_id, :date).each do |d|
        customer_id = d.customer_id
        @report_data[customer_id] = {donations: [], total: donations_by_customer[customer_id]} unless @report_data.has_key?(customer_id)
        customer_donation_data = @report_data[customer_id]
        customer_donation_data[:donations] << [d.date, d.amount]
      end
      @total_amount = donations.sum(:amount)

      if query_params[:report_type] == 'summary'
        @is_summary_report = true
      else
        @customer_trip_sizes = {}
        trips = Trip.for_date_range(@query.start_date, @query.end_date).where(customer_id: customer_ids).order(:customer_id)
        trips.each do |t|
          if @customer_trip_sizes.has_key?(t.customer_id)
            @customer_trip_sizes[t.customer_id] += t.trip_count
          else
            @customer_trip_sizes[t.customer_id] = t.trip_count
          end
        end
      end
    end

    apply_v2_response
  end

  def customers_report
    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @all_mobilities = Mobility.by_provider(current_provider).order(:name)

    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      
      active_customers = Customer.for_provider(current_provider_id).active
      unless @query.mobility_id.blank?
        @mobilities = @all_mobilities.where(id: @query.mobility_id)
        @report_params << [["Mobility Device", @mobilities.first.try(:name)]]
        @customers = active_customers.where(mobility_id: @query.mobility_id)
      else
        @mobilities = @all_mobilities
        @customers = active_customers
      end

      @count_by_mobilities = @customers.reorder('').group(:mobility_id).count
      provider_eligible_age = current_provider.eligible_age || Provider::DEFAULT_ELIGIBLE_AGE
      eligible_birth_date = Date.today - (provider_eligible_age).years
      @age_eligible_count = @customers.where("birth_date is not NULL and birth_date <= ?", eligible_birth_date).count
      @ada_eligible_count = @customers.where(ada_eligible: true).count
      @count_by_eligibility = CustomerEligibility.where(customer_id: @customers.pluck(:id)).eligible.reorder('').group(:eligibility_id).count
      @eligibilities = Eligibility.by_provider(current_provider).order(:description)

      if query_params[:report_type] == 'summary'
        @is_summary_report = true
      end
    end

    apply_v2_response
  end

  # Cancellations, No Show or Missed Trip report
  def cancellations_report
    query_params = params[:query] || {start_date: Date.today.prev_month + 1, end_date: Date.today + 1}
    @query = Query.new(query_params)
    @active_customers = Customer.active_for_date(Date.today).for_provider(current_provider_id)
    
    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      @report_params << ["Date Range", "#{@query.start_date.strftime('%m/%d/%Y')} - #{@query.before_end_date.strftime('%m/%d/%Y')}"]

      unless @query.customer_id.blank?
        @customers = @active_customers.where(id: @query.customer_id)
      else
        @customers = @active_customers
      end

      @cancelled_trips_results = TripResult.where(code: TripResult::NON_DISPATCHABLE_CODES)

      @cancelled_trips = Trip.for_provider(current_provider_id)
        .for_date_range(@query.start_date, @query.end_date)
        .where(trip_result_id: @cancelled_trips_results.pluck(:id))
        .where(customer_id: @customers.pluck(:id))

      @customer_count = @cancelled_trips.group(:trip_result_id).sum("trips.customer_space_count")
      @guest_count = @cancelled_trips.group(:trip_result_id).sum("trips.guest_count")
      @attendant_count = @cancelled_trips.group(:trip_result_id).sum("trips.attendant_count")
      @total_rider_count = @cancelled_trips.group(:trip_result_id).sum("trips.customer_space_count + trips.guest_count + trips.attendant_count")

      @mobility_types = Mobility.by_provider(current_provider).order(:name)
      @mobility_count = @cancelled_trips.joins(:ridership_mobilities).group(:trip_result_id, "ridership_mobility_mappings.mobility_id").sum("ridership_mobility_mappings.capacity")

      if query_params[:report_type] == 'summary'
        @is_summary_report = true
      else
        @customer_names = @cancelled_trips.joins(:customer).reorder("pickup_time::date").order("last_name, first_name, middle_initial").pluck(:first_name, :last_name)
      end
    end

    apply_v2_response
  end

  def driver_report
    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @active_drivers = Driver.for_provider(current_provider_id).active.default_order

    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      
      unless @query.driver_id.blank?
        @drivers = Driver.where(id: @query.driver_id)
      else
        @drivers = @active_drivers
      end

      @total_paid_driver_count = @drivers.where(paid: true).count 
      @total_volunteer_driver_count = @drivers.count - @total_paid_driver_count

      if query_params[:report_type] == 'summary'
        @is_summary_report = true
      else
        
      end
    end

    apply_v2_response
  end

  def driver_compliances_report
    query_params = params[:query] || {start_date: Date.today.prev_month + 1, end_date: Date.today + 1}
    @query = Query.new(query_params)
    @active_drivers = Driver.for_provider(current_provider_id).active.default_order

    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      @report_params << ["Date Range", "#{@query.start_date.strftime('%m/%d/%Y')} - #{@query.before_end_date.strftime('%m/%d/%Y')}"]
      
      unless @query.driver_id.blank?
        @drivers = Driver.where(id: @query.driver_id)
      else
        @drivers = @active_drivers
      end
      driver_ids = @drivers.pluck(:id)
      
      base_driver_compliances = DriverCompliance.for_driver(driver_ids).due_date_range(@query.start_date, @query.end_date).default_order

      if query_params[:report_type] == 'summary'
        @is_summary_report = true 
        # summary report for upcoming events only
        driver_compliances = base_driver_compliances.incomplete
      else
        driver_compliances = base_driver_compliances
        @driver_histories = DriverHistory.for_driver(driver_ids).event_date_range(@query.start_date, @query.end_date).default_order.group_by{|dh| dh.driver_id}
      end

      @legal_compliances = driver_compliances.legal.group_by{|dc| dc.driver_id}
      @non_legal_compliances = driver_compliances.non_legal.group_by{|dc| dc.driver_id}
    end

    apply_v2_response
  end

  def driver_monthly_service_report
    query_params = params[:query] || {start_date: Date.today.prev_month + 1, end_date: Date.today + 1}
    @query = Query.new(query_params)
    @active_drivers = Driver.for_provider(current_provider_id).active.default_order

    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      @report_params << ["Date Range", "#{@query.start_date.strftime('%m/%d/%Y')} - #{@query.before_end_date.strftime('%m/%d/%Y')}"]
      
      unless @query.driver_id.blank?
        @drivers = Driver.where(id: @query.driver_id)
      else
        @drivers = @active_drivers
      end

      @runs = Run.for_provider(current_provider_id).for_driver(@drivers.pluck(:id)).for_date_range(@query.start_date, @query.end_date)

      @total_hours = @runs.sum("extract(epoch from (scheduled_end_time - scheduled_start_time))") / 3600.0
      @service_drivers = Driver.where(id: @runs.pluck(:driver_id).uniq) # drivers that provided service
      @total_driver_count = @service_drivers.count
      @total_paid_driver_count = @runs.joins(:driver).where(drivers: {paid: true}).pluck(:driver_id).uniq.count
      @total_volunteer_driver_count = @total_driver_count - @total_paid_driver_count

      if query_params[:report_type] == 'summary'
        @is_summary_report = true
      else
        @total_runs_completed = @runs.complete.count
        @total_days_worked = @runs.today_and_prior.count(:date)
        @days_worked_by_driver = @runs.today_and_prior.group(:driver_id).count(:date)
        @runs_completed_by_driver = @runs.complete.group(:driver_id).count(:id)
        @seconds_scheduled_by_driver = @runs.group(:driver_id).sum("extract(epoch from (scheduled_end_time - scheduled_start_time))")
      end
    end

    apply_v2_response
  end

  def vehicle_report
    query_params = params[:query] || {start_date: Date.today.prev_month + 1, end_date: Date.today + 1}
    @query = Query.new(query_params)
    @active_vehicles = Vehicle.where(reportable: true).for_provider(current_provider_id).active.default_order

    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      @report_params << ["Date Range", "#{@query.start_date.strftime('%m/%d/%Y')} - #{@query.before_end_date.strftime('%m/%d/%Y')}"]
      
      unless @query.vehicle_id.blank?
        @vehicles = Vehicle.where(id: @query.vehicle_id)
      else
        @vehicles = @active_vehicles
      end
      vehicle_ids = @vehicles.pluck(:id)

      base_compliances = VehicleCompliance.for_vehicle(vehicle_ids).due_date_range(@query.start_date, @query.end_date).default_order

      if query_params[:report_type] == 'summary'
        @is_summary_report = true
      else
        @vehicle_maintenance_compliances = VehicleMaintenanceCompliance.for_vehicle(vehicle_ids).default_order.group_by{|c| c.vehicle_id}
        @vehicle_warranties = VehicleWarranty.for_vehicle(vehicle_ids).default_order.group_by{|c| c.vehicle_id}
        @repair_events = VehicleMaintenanceEvent.for_vehicle(vehicle_ids).default_order.group_by{|c| c.vehicle_id}
      end

      @legal_compliances = base_compliances.legal.group_by{|c| c.vehicle_id}
      @non_legal_compliances = base_compliances.non_legal.group_by{|c| c.vehicle_id}
    end

    apply_v2_response
  end

  def vehicle_5310_report
    query_params = params[:query] || {start_date: Date.today, end_date: Date.today + 1}
    @query = Query.new(query_params)
    @active_vehicles = Vehicle.is_5310_reportable.for_provider(current_provider_id).active.default_order

    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      @report_params << ["Date Range", "#{@query.start_date.strftime('%m/%d/%Y')} - #{@query.before_end_date.strftime('%m/%d/%Y')}"]
      
      unless @query.vehicle_id.blank?
        @vehicles = Vehicle.where(id: @query.vehicle_id)
      else
        @vehicles = @active_vehicles
      end
      vehicle_ids = @vehicles.pluck(:id)

      # Only past runs with odometers
      @runs = Run.with_odometer_readings.today_and_prior.for_provider(current_provider_id).for_vehicle(@vehicles.pluck(:id)).for_date_range(@query.start_date, @query.end_date)
      run_trips = @runs.joins(:trips).where("trips.trip_result_id is NULL or trips.trip_result_id = ?", TripResult.find_by_code('COMP').try(:id))
      # Total passenger count
      @total_passengers_count = run_trips.sum("customer_space_count + guest_count + attendant_count")
      @total_senior_passengers_count = run_trips.sum(:number_of_senior_passengers_served)
      @total_disabled_passengers_count = run_trips.sum(:number_of_disabled_passengers_served)
      @total_low_income_passengers_count = run_trips.sum(:number_of_low_income_passengers_served)

      if query_params[:report_type] == 'summary'
        @is_summary_report = true
      else
        # stats
        @passengers_count = run_trips.group(:vehicle_id).sum("customer_space_count + guest_count + attendant_count")
        @senior_passengers_count = run_trips.group(:vehicle_id).sum(:number_of_senior_passengers_served)
        @disabled_passengers_count = run_trips.group(:vehicle_id).sum(:number_of_disabled_passengers_served)
        @low_income_passengers_count = run_trips.group(:vehicle_id).sum(:number_of_low_income_passengers_served)
        @miles_by_vehicle = @runs.group(:vehicle_id).sum("(end_odometer - start_odometer)")
        @run_last_complete_dates = @runs.group(:vehicle_id).pluck(:vehicle_id, "max(runs.date)").to_h

        # compliances
        base_compliances = VehicleCompliance.for_vehicle(vehicle_ids).due_date_range(@query.start_date, @query.end_date).default_order

        @vehicle_maintenance_compliances = VehicleMaintenanceCompliance.for_vehicle(vehicle_ids).default_order.group_by{|c| c.vehicle_id}
        @vehicle_warranties = VehicleWarranty.for_vehicle(vehicle_ids).default_order.group_by{|c| c.vehicle_id}
        @repair_events = VehicleMaintenanceEvent.for_vehicle(vehicle_ids).default_order.group_by{|c| c.vehicle_id}

        @legal_compliances = base_compliances.legal.group_by{|c| c.vehicle_id}
        @non_legal_compliances = base_compliances.non_legal.group_by{|c| c.vehicle_id}
      end
    end

    apply_v2_response
  end

  def vehicle_monthly_service_report
    query_params = params[:query] || {start_date: Date.today.prev_month + 1, end_date: Date.today + 1}
    @query = Query.new(query_params)
    @active_vehicles = Vehicle.where(reportable: true).for_provider(current_provider_id).active.default_order

    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      @report_params << ["Date Range", "#{@query.start_date.strftime('%m/%d/%Y')} - #{@query.before_end_date.strftime('%m/%d/%Y')}"]
      
      unless @query.vehicle_id.blank?
        @vehicles = Vehicle.where(id: @query.vehicle_id)
      else
        @vehicles = @active_vehicles
      end

      # Only past runs with odometers
      @runs = Run.with_odometer_readings.today_and_prior.for_provider(current_provider_id).for_vehicle(@vehicles.pluck(:id)).for_date_range(@query.start_date, @query.end_date)

      @service_vehicles = Vehicle.where(id: @runs.pluck(:vehicle_id).uniq) # vehicles that provided service
      @total_vehicle_count = @service_vehicles.count
      @total_vehicle_miles = @runs.sum("(end_odometer - start_odometer)")
      @miles_by_vehicle = @runs.group(:vehicle_id).sum("(end_odometer - start_odometer)")
      @vehicle_hours = @runs.group(:vehicle_id).sum("extract(epoch from (scheduled_end_time - scheduled_start_time))")
      @total_vehicle_hours = @runs.total_scheduled_hours
      run_trips = @runs.joins(:trips).where("trips.trip_result_id is NULL or trips.trip_result_id = ?", TripResult.find_by_code('COMP').try(:id))
      @trips_count = run_trips.group(:vehicle_id).count
      @total_trips_count = run_trips.count
      # Total passenger count
      @passengers_count = run_trips.group(:vehicle_id).sum("customer_space_count + guest_count + attendant_count")
      @total_passengers_count = run_trips.sum("customer_space_count + guest_count + attendant_count")

      if query_params[:report_type] == 'summary'
        @is_summary_report = true
      else
        @run_dates = @runs.pluck(:date).uniq.sort
        @vehicles_basic_data = @service_vehicles.pluck(:id, :name)
        # by day and vehicle, and day total
        # mileage, number of trips, begining & ending mileage, revenue and non-revenue miles
        @report_data = {}
        @report_data_totals = {}
        @runs.joins(:trips, "left join run_distances on run_distances.run_id = runs.id")
          .where("trips.trip_result_id is NULL or trips.trip_result_id = ?", TripResult.find_by_code('COMP').try(:id))
          .select(:date, :vehicle_id)
          .select("count(trips.id) as trips_count", "SUM(runs.end_odometer - runs.start_odometer)/ count(trips.id) as mileage")
          .select("min(start_odometer) as beginning_mileage", "max(end_odometer) as ending_mileage")
          .select("sum(run_distances.revenue_miles) / count(trips.id) as revenue_miles_sum", "sum(run_distances.non_revenue_miles) / count(trips.id) as non_revenue_miles_sum")
          .group(:date, :vehicle_id).each do |run_data|
          date = run_data.date
          @report_data[date] = {} unless @report_data.has_key?(date)
          @report_data_totals[date] = {
            mileage: 0,
            trips_count: 0,
            revenue_miles_sum: nil,
            non_revenue_miles_sum: nil
          } unless @report_data_totals.has_key?(date)

          @report_data[date][run_data.vehicle_id] = {
            mileage: run_data.mileage,
            trips_count: run_data.trips_count,
            beginning_mileage: run_data.beginning_mileage,
            ending_mileage: run_data.ending_mileage,
            revenue_miles_sum: run_data.revenue_miles_sum,
            non_revenue_miles_sum: run_data.non_revenue_miles_sum
          }

          @report_data_totals[date][:mileage] += run_data.mileage.to_f
          @report_data_totals[date][:trips_count] += run_data.trips_count.to_i
          @report_data_totals[date][:revenue_miles_sum] = @report_data_totals[date][:revenue_miles_sum].to_f +  run_data.revenue_miles_sum.to_f if run_data.revenue_miles_sum
          @report_data_totals[date][:non_revenue_miles_sum] = @report_data_totals[date][:non_revenue_miles_sum].to_f + run_data.non_revenue_miles_sum.to_f if run_data.non_revenue_miles_sum

        end

      end
    end

    apply_v2_response
  end

  def provider_service_productivity_report
    query_params = params[:query] || {start_date: Date.today.prev_month + 1, end_date: Date.today + 1}
    @query = Query.new(query_params)
    @active_vehicles = Vehicle.for_provider(current_provider_id).active.default_order

    if params[:query]
      @report_params = [["Provider", current_provider.name]]
      @report_params << ["Date Range", "#{@query.start_date.strftime('%m/%d/%Y')} - #{@query.before_end_date.strftime('%m/%d/%Y')}"]
      
      unless @query.vehicle_id.blank?
        @vehicles = Vehicle.where(id: @query.vehicle_id)
      else
        @vehicles = @active_vehicles
      end

      # Only past runs with odometers
      @runs = Run.with_odometer_readings.today_and_prior.for_provider(current_provider_id).for_vehicle(@vehicles.pluck(:id)).for_date_range(@query.start_date, @query.end_date)

      @service_vehicles = Vehicle.where(id: @runs.pluck(:vehicle_id).uniq) # vehicles that provided service
      run_trips = @runs.joins(:trips).where("trips.trip_result_id is NULL or trips.trip_result_id = ?", TripResult.find_by_code('COMP').try(:id))
      @total_trips_count = run_trips.count

      # Total passenger count
      @total_customer_count = run_trips.sum("customer_space_count")
      @total_guest_count = run_trips.sum("guest_count")
      @total_attendant_count = run_trips.sum("attendant_count")
      @total_service_animal_count = run_trips.sum("service_animal_space_count")
      @total_passengers_count = @total_customer_count + @total_guest_count + @total_attendant_count + @total_service_animal_count

      # Trips by funding source
      run_trips_group_by_funding_source = run_trips.group("trips.funding_source_id")
      @trip_count_by_funding_source = run_trips_group_by_funding_source.count
      @customer_count_by_funding_source = run_trips_group_by_funding_source.sum("customer_space_count")
      @guest_count_by_funding_source = run_trips_group_by_funding_source.sum("guest_count")
      @attendant_count_by_funding_source = run_trips_group_by_funding_source.sum("attendant_count")
      @service_animal_count_by_funding_source = run_trips_group_by_funding_source.sum("service_animal_space_count")

      if query_params[:report_type] == 'summary'
        @is_summary_report = true
      else
        @run_dates = @runs.pluck(:date).uniq.sort

        run_trips = @runs.joins(:trips).where("trips.trip_result_id is NULL or trips.trip_result_id = ?", TripResult.find_by_code('COMP').try(:id))
        @ride_counts_by_trip_purpose = run_trips.group(:date, "trips.trip_purpose_id").count
        @ride_counts_by_date = run_trips.group(:date).count
        @mobility_counts = @runs.joins(trips: :ridership_mobilities)
          .where("trips.trip_result_id is NULL or trips.trip_result_id = ?", TripResult.find_by_code('COMP').try(:id))
          .where("ridership_mobility_mappings.capacity > 0")
          .group(:date, "ridership_mobility_mappings.mobility_id")
          .sum("ridership_mobility_mappings.capacity")
      end
    end

    apply_v2_response
  end

  def manifest
    query_params = params[:query] || {start_date: Date.today, end_date: Date.today + 1}
    @query = Query.new(query_params)
    @runs_with_trips = Run.for_provider(current_provider_id).for_date_range(@query.start_date, @query.end_date).joins(:trips).distinct
    @all_runs = @runs_with_trips.reorder(:date, :name)

    if params[:query]
      @report_params = [["Provider", current_provider.name]]
        
      @capacity_types_hash = CapacityType.by_provider(current_provider).pluck(:id, :name).to_h
      if @query.run_ids && !@query.run_ids.blank?
        @runs = Run.where(id: @query.run_ids)
      else
        @runs = @all_runs
      end

      @runs = @runs.includes(trips: [:pickup_address, :dropoff_address, :customer])
        .references(trips: [:pickup_address, :dropoff_address, :customer])
        .reorder(:date, :scheduled_start_time)  
    end

    apply_v2_response
  end

  def ntd
    query_params = params[:query] || {start_date: Date.today, end_date: Date.today + 1}
    @query = Query.new(query_params)

    if params[:query]
      @excel_file_name = "NTD_#{@query.ntd_year}_#{@query.ntd_month}"
      @workbook = NtdReport.new(current_provider, @query.ntd_year, @query.ntd_month).export!
    end

    apply_v2_response
  end

  def pre_run_inspections
    query_params = params[:query] || {start_date: Date.today.prev_month + 1, end_date: Date.today + 1}
    @query = Query.new(query_params)
    @active_vehicles = Vehicle.for_provider(current_provider_id).active.default_order
    
    if params[:query]
      @report_params = []
      @report_params << ["Date Range", "#{@query.start_date.strftime('%m/%d/%Y')} - #{@query.before_end_date.strftime('%m/%d/%Y')}"]
      @report_params << ["Inspection Type", @query.run_inspection_type.titleize] if @query.run_inspection_type

      # get failed inspections
      @inspections = RunVehicleInspection.joins(run: :vehicle).joins(:vehicle_inspection)
                      .where("runs.provider_id": current_provider_id)
                      .where("runs.date >= ? and runs.date < ?", @query.start_date, @query.end_date)
                      .where(checked: false)
                      .order("lower(vehicles.name)", "runs.date", "runs.scheduled_start_time_string", "vehicle_inspections.description")
      
      @inspections = @inspections.where("runs.vehicle_id": @query.vehicle_id) if @query.vehicle_id

      # TODO: filter by inspection question type (flaggable or mechanical)
      if @query.run_inspection_type == 'flagged'
        @inspections = @inspections.where("vehicle_inspections.flagged": true) 
      elsif @query.run_inspection_type == 'mechanical'
        @inspections = @inspections.where("vehicle_inspections.mechanical": true) 
      end

      # get notes provided by driver
      run_ids = @inspections.pluck(:run_id).uniq
      runs = Run.where(id: run_ids)
      run_data_array = runs.pluck(:id, :name, :date, :driver_notes)
      @run_data = Hash[run_data_array.collect { |item| [item[0], item[1..-1]] } ]

      # formulate report data
      @report_data = {}
      @inspections.pluck("runs.vehicle_id", "runs.id", "vehicle_inspections.description").each do |insp_data|
        vehicle_id = insp_data[0]
        run_id = insp_data[1]
        @report_data[vehicle_id] = {} unless @report_data[vehicle_id]
        vehicle_data = @report_data[vehicle_id]
        vehicle_data[run_id] = [] unless vehicle_data[run_id]
        vehicle_data[run_id] << insp_data[2]
      end
      @vehicle_names = Vehicle.where(id: @report_data.keys.uniq).pluck(:id, :name).to_h
    end

    apply_v2_response
  end

  # refresh run dropdown whenever date range is changed
  def get_run_list
    query_params = params[:query]
    @query = Query.new(query_params)
    @runs_with_trips = Run.for_provider(current_provider_id).for_date_range(@query.start_date, @query.end_date).joins(:trips).distinct
    @all_runs = @runs_with_trips.reorder(:date, :name)  
  end

  # show save form
  def show_save_form
    @custom_report = CustomReport.find_by_id params[:custom_report_id]
    @new_saved_report = SavedCustomReport.new(provider: current_provider, custom_report: @custom_report)
  end

  # Save custom report params so can re-run in the future
  def save_as
    @new_saved_report = SavedCustomReport.new(provider: current_provider)
    @new_saved_report.attributes = saved_custom_report_params
    if !@new_saved_report.save
      render :show_save_form
    else
      @reports = all_report_infos
    end
  end

  def delete_saved_report
    @saved_report = SavedCustomReport.find_by_id(params[:id])

    if @saved_report 
      custom_report = @saved_report.custom_report
      report_name = @saved_report.name
      @saved_report.destroy
      flash[:notice] = "#{report_name} has been deleted."
      redirect_to custom_report_path(custom_report)
    else
      flash[:error] = "Failed to delete #{saved_report.name}."
      redirect_back(fallback_location: saved_report_path(@saved_report))
    end
  end

  # Show saved report results
  def saved_report
    @saved_report = SavedCustomReport.find_by_id(params[:id])
    @is_saved_report = true

    if @saved_report
      @custom_report = @saved_report.custom_report
      unless @saved_report.report_params.blank?
        report_params = Rack::Utils.parse_nested_query @saved_report.report_params
        
        params[:query] = report_params["query"]

        process_saved_date_params

        query_params = params[:query] || {}
        @query = Query.new(query_params)

        if @saved_report.date_range_type == SavedCustomReport::PROMPT_DATES 
          @query.start_date = nil 
          @query.before_end_date = nil
        end
      end
    end
  end

  def show_saved_report
    @saved_report = SavedCustomReport.find_by_id(params[:id])
    @is_saved_report = true

    if @saved_report
      @custom_report = @saved_report.custom_report
      send(@custom_report.name) if @custom_report
    end
  end

  private

  def set_reports
    @reports = all_report_infos # get all report infos (id, name) both generic and customized reports
  end

  def set_custom_report
    @custom_report = CustomReport.find params[:id]
  end

  def saved_custom_report_params
    params.require(:saved_custom_report).permit(:name, :custom_report_id, :date_range_type, :report_params)
  end

  def prep_with_cab
    authorize! :read, Trip

    query_params = params[:query] || {}
    @query = Query.new(query_params)
    @date = @query.start_date

    trips = Trip.empty_or_completed.for_provider(current_provider_id).for_date(@date).includes(:pickup_address,:dropoff_address,:customer,:mobility,{:run => :driver}).order(:pickup_time)
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

  def pdf_template
    report_name = @custom_report.name
    layout = report_name == 'manifest' ? 'portrait' : 'landscape'

    {
      pdf: "#{report_name}",
      disposition: 'attachment',
      :margin => {
          :top => 30,
          :bottom => 10
      },
      :header => {
          :spacing => 20,
          :html => {
              :template => "reports/pdf_header.pdf.haml"
          }
      },
      :show_as_html => params[:debug].present?,
      :template => "reports/show.pdf.haml",
      :layout => 'pdf.html',
      :orientation => layout,
      :footer => {
          :center => view_context.format_for_pdf_printing(Time.now),
          :right => 'Page [page] of [topage]'
      }
    }
  end

  def apply_v2_response
    request.format = @query.report_format if @query && @query.report_format
    respond_to do |format|
      format.html
      format.csv do 
        headers['Content-Disposition'] = "attachment;filename=#{@custom_report.name}.csv"
        render template: "reports/show.csv.haml"
      end

      format.xlsx do 
        send_data( @workbook.stream.read, {
          :disposition => 'attachment',
          :type => 'application/excel',
          :filename => "#{@excel_file_name || @custom_report.name}.xlsx"
        })
      end

      format.pdf do
        render pdf_template
      end
    end
  end

  # given saved report date range type, re-process date range params
  def process_saved_date_params
    case @saved_report.date_range_type
    when SavedCustomReport::LAST_7_DAYS
      before_end_date = Date.today
      start_date = before_end_date - 7.days
    when SavedCustomReport::THIS_WEEK
      before_end_date = Date.today
      start_date = before_end_date.beginning_of_week(start_day = :sunday)
    when SavedCustomReport::LAST_WEEK
      before_end_date = (Date.today - 1.week).end_of_week(start_day = :sunday)
      start_date = before_end_date.beginning_of_week(start_day = :sunday)
    when SavedCustomReport::LAST_30_DAYS
      before_end_date = Date.today
      start_date = before_end_date - 30.days
    when SavedCustomReport::THIS_MONTH
      before_end_date = Date.today
      start_date = before_end_date.beginning_of_month
    when SavedCustomReport::LAST_MONTH
      before_end_date = (Date.today - 1.month).end_of_month
      start_date = before_end_date.beginning_of_month
    when SavedCustomReport::THIS_QUARTER
      before_end_date = Date.today
      start_date = before_end_date.beginning_of_quarter
    when SavedCustomReport::YEAR_TO_DATE
      before_end_date = Date.today
      start_date = before_end_date.beginning_of_year
    when SavedCustomReport::LAST_YEAR
      before_end_date = (Date.today - 1.year).end_of_year
      start_date = before_end_date.beginning_of_year
    end

    if before_end_date && start_date
      params[:query]["start_date(1i)"] = start_date.year
      params[:query]["start_date(2i)"] = start_date.month
      params[:query]["start_date(3i)"] = start_date.day
      params[:query]["before_end_date(1i)"] = before_end_date.year
      params[:query]["before_end_date(2i)"] = before_end_date.month
      params[:query]["before_end_date(3i)"] = before_end_date.day
    end

  end
end
