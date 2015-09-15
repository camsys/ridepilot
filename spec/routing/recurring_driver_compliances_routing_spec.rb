require "rails_helper"

RSpec.describe RecurringDriverCompliancesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/recurring_driver_compliances").to route_to("recurring_driver_compliances#index")
    end

    it "routes to #new" do
      expect(:get => "/recurring_driver_compliances/new").to route_to("recurring_driver_compliances#new")
    end

    it "routes to #show" do
      expect(:get => "/recurring_driver_compliances/1").to route_to("recurring_driver_compliances#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/recurring_driver_compliances/1/edit").to route_to("recurring_driver_compliances#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/recurring_driver_compliances").to route_to("recurring_driver_compliances#create")
    end

    it "routes to #update" do
      expect(:put => "/recurring_driver_compliances/1").to route_to("recurring_driver_compliances#update", :id => "1")
    end

    it "routes to #delete" do
      expect(:get => "/recurring_driver_compliances/1/delete").to route_to("recurring_driver_compliances#delete", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/recurring_driver_compliances/1").to route_to("recurring_driver_compliances#destroy", :id => "1")
    end

    it "routes to #schedule_preview" do
      expect(:get => "/recurring_driver_compliances/schedule_preview").to route_to("recurring_driver_compliances#schedule_preview")
    end

    it "routes to #future_schedule_preview" do
      expect(:get => "/recurring_driver_compliances/future_schedule_preview").to route_to("recurring_driver_compliances#future_schedule_preview")
    end

    it "routes to #compliance_based_schedule_preview" do
      expect(:get => "/recurring_driver_compliances/compliance_based_schedule_preview").to route_to("recurring_driver_compliances#compliance_based_schedule_preview")
    end
  end
end
