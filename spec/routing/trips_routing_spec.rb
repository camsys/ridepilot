require "rails_helper"

RSpec.describe TripsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/trips").to route_to("trips#index")
    end

    it "routes to #new" do
      expect(:get => "/trips/new").to route_to("trips#new")
    end

    it "routes to #show" do
      expect(:get => "/trips/1").to route_to("trips#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/trips/1/edit").to route_to("trips#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/trips").to route_to("trips#create")
    end

    it "routes to #update" do
      expect(:put => "/trips/1").to route_to("trips#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/trips/1").to route_to("trips#destroy", :id => "1")
    end

    it "routes to #confirm" do
      expect(:post => "/trips/1/confirm").to route_to("trips#confirm", :trip_id => "1")
    end

    it "routes to #no_show" do
      expect(:post => "/trips/1/no_show").to route_to("trips#no_show", :trip_id => "1")
    end

    it "routes to #reached" do
      expect(:post => "/trips/1/reached").to route_to("trips#reached", :trip_id => "1")
    end

    it "routes to #send_to_cab" do
      expect(:post => "/trips/1/send_to_cab").to route_to("trips#send_to_cab", :trip_id => "1")
    end

    it "routes to #turndown" do
      expect(:post => "/trips/1/turndown").to route_to("trips#turndown", :trip_id => "1")
    end

    it "routes to #reconcile_cab" do
      expect(:get => "/trips/reconcile_cab").to route_to("trips#reconcile_cab")
    end

    it "routes to #trips_requiring_callback" do
      expect(:get => "/trips/trips_requiring_callback").to route_to("trips#trips_requiring_callback")
    end

    it "routes to #unscheduled" do
      expect(:get => "/trips/unscheduled").to route_to("trips#unscheduled")
    end

  end
end
