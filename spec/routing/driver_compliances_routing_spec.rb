require "rails_helper"

RSpec.describe DriverCompliancesController, type: :routing do
  describe "routing" do
    describe "nested on drivers" do
      it "does not route to #index" do
        expect(:get => "/drivers/1/driver_compliances").not_to route_to("driver_compliances#index", driver_id: "1")
      end

      it "routes to #new" do
        expect(:get => "/drivers/1/driver_compliances/new").to route_to("driver_compliances#new", driver_id: "1")
      end

      it "does not route to #show" do
        expect(:get => "/drivers/1/driver_compliances/1").not_to route_to("driver_compliances#show", id: "1", driver_id: "1")
      end

      it "routes to #edit" do
        expect(:get => "/drivers/1/driver_compliances/1/edit").to route_to("driver_compliances#edit", :id => "1", driver_id: "1")
      end

      it "routes to #create" do
        expect(:post => "/drivers/1/driver_compliances").to route_to("driver_compliances#create", driver_id: "1")
      end

      it "routes to #update" do
        expect(:put => "/drivers/1/driver_compliances/1").to route_to("driver_compliances#update", :id => "1", driver_id: "1")
      end

      it "routes to #destroy" do
        expect(:delete => "/drivers/1/driver_compliances/1").to route_to("driver_compliances#destroy", :id => "1", driver_id: "1")
      end
    end
  end
end
