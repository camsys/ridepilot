require "rails_helper"

RSpec.describe VehicleMaintenanceCompliancesController, type: :routing do
  describe "routing" do
    describe "nested on vehicles" do
      it "does not route to #index" do
        expect(:get => "/vehicles/1/vehicle_maintenance_compliances").not_to route_to("vehicle_maintenance_compliances#index", vehicle_id: "1")
      end

      it "routes to #new" do
        expect(:get => "/vehicles/1/vehicle_maintenance_compliances/new").to route_to("vehicle_maintenance_compliances#new", vehicle_id: "1")
      end

      it "does not route to #show" do
        expect(:get => "/vehicles/1/vehicle_maintenance_compliances/1").not_to route_to("vehicle_histories#show", id: "1", vehicle_id: "1")
      end

      it "routes to #edit" do
        expect(:get => "/vehicles/1/vehicle_maintenance_compliances/1/edit").to route_to("vehicle_maintenance_compliances#edit", :id => "1", vehicle_id: "1")
      end

      it "routes to #create" do
        expect(:post => "/vehicles/1/vehicle_maintenance_compliances").to route_to("vehicle_maintenance_compliances#create", vehicle_id: "1")
      end

      it "routes to #update" do
        expect(:put => "/vehicles/1/vehicle_maintenance_compliances/1").to route_to("vehicle_maintenance_compliances#update", :id => "1", vehicle_id: "1")
      end

      it "routes to #destroy" do
        expect(:delete => "/vehicles/1/vehicle_maintenance_compliances/1").to route_to("vehicle_maintenance_compliances#destroy", :id => "1", vehicle_id: "1")
      end
    end
  end
end
