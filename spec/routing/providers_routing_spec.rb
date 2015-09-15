require "rails_helper"

RSpec.describe ProvidersController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/providers").to route_to("providers#index")
    end

    it "routes to #new" do
      expect(:get => "/providers/new").to route_to("providers#new")
    end

    it "routes to #show" do
      expect(:get => "/providers/1").to route_to("providers#show", :id => "1")
    end

    it "does not route to #edit" do
      expect(:get => "/providers/1/edit").to_not route_to("providers#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/providers").to route_to("providers#create")
    end

    it "does not route to #update" do
      expect(:put => "/providers/1").to_not route_to("providers#update", :id => "1")
    end

    it "does not route to #destroy" do
      expect(:delete => "/providers/1").to_not route_to("providers#destroy", :id => "1")
    end

    it "routes to #change_dispatch" do
      expect(:post => "/providers/1/change_dispatch").to route_to("providers#change_dispatch", :id => "1")
    end

    it "routes to #change_reimbursement_rates" do
      expect(:post => "/providers/1/change_reimbursement_rates").to route_to("providers#change_reimbursement_rates", :id => "1")
    end

    it "routes to #change_scheduling" do
      expect(:post => "/providers/1/change_scheduling").to route_to("providers#change_scheduling", :id => "1")
    end

    it "routes to #change_allow_trip_entry_from_runs_page" do
      expect(:post => "/providers/1/change_allow_trip_entry_from_runs_page").to route_to("providers#change_allow_trip_entry_from_runs_page", :id => "1")
    end

    it "routes to #change_fields_required_for_run_completion" do
      expect(:post => "/providers/1/change_fields_required_for_run_completion").to route_to("providers#change_fields_required_for_run_completion", :id => "1")
    end

    it "routes to #save_region" do
      expect(:post => "/providers/1/save_region").to route_to("providers#save_region", :id => "1")
    end

    it "routes to #save_viewport" do
      expect(:post => "/providers/1/save_viewport").to route_to("providers#save_viewport", :id => "1")
    end

    it "routes to #change_role" do
      expect(:post => "/providers/1/change_role").to route_to("providers#change_role", :provider_id => "1")
    end

    it "routes to #delete_role" do
      expect(:post => "/providers/1/delete_role").to route_to("providers#delete_role", :provider_id => "1")
    end

  end
end
