require "rails_helper"

RSpec.describe DriverHistoriesController, type: :routing do
  describe "routing" do
    describe "nested on drivers" do
      it "does not route to #index" do
        expect(:get => "/drivers/1/driver_histories").not_to route_to("driver_histories#index", driver_id: "1")
      end

      it "routes to #new" do
        expect(:get => "/drivers/1/driver_histories/new").to route_to("driver_histories#new", driver_id: "1")
      end

      it "does not route to #show" do
        expect(:get => "/drivers/1/driver_histories/1").not_to route_to("driver_histories#show", id: "1", driver_id: "1")
      end

      it "routes to #edit" do
        expect(:get => "/drivers/1/driver_histories/1/edit").to route_to("driver_histories#edit", :id => "1", driver_id: "1")
      end

      it "routes to #create" do
        expect(:post => "/drivers/1/driver_histories").to route_to("driver_histories#create", driver_id: "1")
      end

      it "routes to #update" do
        expect(:put => "/drivers/1/driver_histories/1").to route_to("driver_histories#update", :id => "1", driver_id: "1")
      end

      it "routes to #destroy" do
        expect(:delete => "/drivers/1/driver_histories/1").to route_to("driver_histories#destroy", :id => "1", driver_id: "1")
      end
    end
  end
end
