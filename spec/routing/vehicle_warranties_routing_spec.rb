require "rails_helper"

RSpec.describe VehicleWarrantiesController, type: :routing do
  describe "routing" do
    describe "nested on vehicles" do
      it "does not route to #index" do
        expect(:get => "/vehicles/1/vehicle_warranties").not_to route_to("vehicle_warranties#index", vehicle_id: "1")
      end

      it "does not route to #show" do
        expect(:get => "/vehicles/1/vehicle_warranties/1").to_not route_to("vehicle_warranties#show", vehicle_id: "1", :id => "1")
      end

      it "routes to #new" do
        expect(:get => "/vehicles/1/vehicle_warranties/new").to route_to("vehicle_warranties#new", vehicle_id: "1")
      end

      it "routes to #edit" do
        expect(:get => "/vehicles/1/vehicle_warranties/1/edit").to route_to("vehicle_warranties#edit", vehicle_id: "1", :id => "1")
      end

      it "routes to #create" do
        expect(:post => "/vehicles/1/vehicle_warranties").to route_to("vehicle_warranties#create", vehicle_id: "1")
      end

      it "routes to #update" do
        expect(:put => "/vehicles/1/vehicle_warranties/1").to route_to("vehicle_warranties#update", vehicle_id: "1", :id => "1")
      end

      it "routes to #destroy" do
        expect(:delete => "/vehicles/1/vehicle_warranties/1").to route_to("vehicle_warranties#destroy", vehicle_id: "1", :id => "1")
      end
    end
  end
end
