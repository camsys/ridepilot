require "rails_helper"

RSpec.describe DocumentsController, type: :routing do
  describe "routing" do
    describe "nested on drivers" do
      it "does not route to #index" do
        expect(:get => "/drivers/1/documents").not_to route_to("documents#index", driver_id: "1")
      end

      it "routes to #new" do
        expect(:get => "/drivers/1/documents/new").to route_to("documents#new", driver_id: "1")
      end

      it "does not route to #show" do
        expect(:get => "/drivers/1/documents/1").not_to route_to("documents#show", driver_id: "1", id: "1")
      end

      it "routes to #edit" do
        expect(:get => "/drivers/1/documents/1/edit").to route_to("documents#edit", driver_id: "1", id: "1")
      end

      it "routes to #create" do
        expect(:post => "/drivers/1/documents").to route_to("documents#create", driver_id: "1")
      end

      it "routes to #update" do
        expect(:put => "/drivers/1/documents/1").to route_to("documents#update", driver_id: "1", id: "1")
      end

      it "routes to #destroy" do
        expect(:delete => "/drivers/1/documents/1").to route_to("documents#destroy", driver_id: "1", id: "1")
      end
    end

    describe "nested on vehicles" do
      it "does not route to #index" do
        expect(:get => "/vehicles/1/documents").not_to route_to("documents#index", vehicle_id: "1")
      end

      it "routes to #new" do
        expect(:get => "/vehicles/1/documents/new").to route_to("documents#new", vehicle_id: "1")
      end

      it "does not route to #show" do
        expect(:get => "/vehicles/1/documents/1").not_to route_to("documents#show", vehicle_id: "1", id: "1")
      end

      it "routes to #edit" do
        expect(:get => "/vehicles/1/documents/1/edit").to route_to("documents#edit", vehicle_id: "1", id: "1")
      end

      it "routes to #create" do
        expect(:post => "/vehicles/1/documents").to route_to("documents#create", vehicle_id: "1")
      end

      it "routes to #update" do
        expect(:put => "/vehicles/1/documents/1").to route_to("documents#update", vehicle_id: "1", id: "1")
      end

      it "routes to #destroy" do
        expect(:delete => "/vehicles/1/documents/1").to route_to("documents#destroy", vehicle_id: "1", id: "1")
      end
    end
  end
end
