require "rails_helper"

RSpec.describe DriversController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/drivers").to route_to("drivers#index")
    end

    it "routes to #new" do
      expect(:get => "/drivers/new").to route_to("drivers#new")
    end

    it "routes to #show" do
      expect(:get => "/drivers/1").to route_to("drivers#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/drivers/1/edit").to route_to("drivers#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/drivers").to route_to("drivers#create")
    end

    it "routes to #update" do
      expect(:put => "/drivers/1").to route_to("drivers#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/drivers/1").to route_to("drivers#destroy", :id => "1")
    end
  end
end
