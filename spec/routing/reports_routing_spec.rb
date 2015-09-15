require "rails_helper"

RSpec.describe ReportsController, type: :routing do
  describe "routing" do

    it "routes to #age_and_ethnicity" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/age_and_ethnicity").to route_to("reports#age_and_ethnicity")
    end

    it "routes to #cab" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/cab").to route_to("reports#cab")
    end

    it "routes to #cctc_summary_report" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/cctc_summary_report").to route_to("reports#cctc_summary_report")
    end

    it "routes to #customer_receiving_trips_in_range" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/customer_receiving_trips_in_range").to route_to("reports#customer_receiving_trips_in_range")
    end

    it "routes to #daily_manifest" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/daily_manifest").to route_to("reports#daily_manifest")
    end

    it "routes to #daily_manifest_by_half_hour" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/daily_manifest_by_half_hour").to route_to("reports#daily_manifest_by_half_hour")
    end

    it "routes to #daily_manifest_by_half_hour_with_cab" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/daily_manifest_by_half_hour_with_cab").to route_to("reports#daily_manifest_by_half_hour_with_cab")
    end

    it "routes to #daily_manifest_with_cab" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/daily_manifest_with_cab").to route_to("reports#daily_manifest_with_cab")
    end

    it "routes to #daily_trips" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/daily_trips").to route_to("reports#daily_trips")
    end

    it "routes to #donations" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/donations").to route_to("reports#donations")
    end

    it "routes to #export_trips_in_range" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/export_trips_in_range").to route_to("reports#export_trips_in_range")
    end

    it "routes to #service_summary" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/service_summary").to route_to("reports#service_summary")
    end

    it "routes to #show_runs_for_verification" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/show_runs_for_verification").to route_to("reports#show_runs_for_verification")
    end

    it "routes to #show_trips_for_verification" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/show_trips_for_verification").to route_to("reports#show_trips_for_verification")
    end

    it "routes to #update_runs_for_verification" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/update_runs_for_verification").to route_to("reports#update_runs_for_verification")
    end

    it "routes to #update_trips_for_verification" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/update_trips_for_verification").to route_to("reports#update_trips_for_verification")
    end

    it "routes to #vehicles_monthly" do
      skip("These routes aren't working... yet")
      expect(:post => "/reports/vehicles_monthly").to route_to("reports#vehicles_monthly")
    end

  end
end
