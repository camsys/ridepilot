require "rails_helper"

RSpec.describe VehicleMaintenanceEventsController, type: :routing do
  describe "routing" do
    describe "nested on vehicles" do
      it "does not route to #index" do
        expect(:get => "/vehicles/1/vehicle_maintenance_events").not_to route_to("vehicle_maintenance_events#index", vehicle_id: "1")
      end

      it "does not route to #show" do
        expect(:get => "/vehicles/1/vehicle_maintenance_events/1").to_not route_to("vehicle_maintenance_events#show", vehicle_id: "1", :id => "1")
      end

      it "routes to #new" do
        expect(:get => "/vehicles/1/vehicle_maintenance_events/new").to route_to("vehicle_maintenance_events#new", vehicle_id: "1")
      end

      it "routes to #edit" do
        expect(:get => "/vehicles/1/vehicle_maintenance_events/1/edit").to route_to("vehicle_maintenance_events#edit", vehicle_id: "1", :id => "1")
      end

      it "routes to #create" do
        expect(:post => "/vehicles/1/vehicle_maintenance_events").to route_to("vehicle_maintenance_events#create", vehicle_id: "1")
      end

      it "routes to #update" do
        expect(:put => "/vehicles/1/vehicle_maintenance_events/1").to route_to("vehicle_maintenance_events#update", vehicle_id: "1", :id => "1")
      end

      it "routes to #destroy" do
        expect(:delete => "/vehicles/1/vehicle_maintenance_events/1").to route_to("vehicle_maintenance_events#destroy", vehicle_id: "1", :id => "1")
      end
    end
  end
end
