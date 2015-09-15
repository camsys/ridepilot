require "rails_helper"

RSpec.describe "VehicleMaintenanceEvents" do
  context "for admin" do
    before :each do
      @admin = create(:admin)
      visit new_user_session_path
      fill_in 'Email', :with => @admin.email
      fill_in 'Password', :with => @admin.password
      click_button 'Log In'
      
      @vehicle = create :vehicle, :provider => @admin.current_provider
      @vehicle_maintenance_event = create :vehicle_maintenance_event, vehicle: @vehicle, service_date: Date.current
    end
    
    it_behaves_like "it accepts nested attributes for document associations" do
      before do
        @owner = @vehicle
        @example = @vehicle_maintenance_event
      end
    end

    describe "GET /vehicles/:id" do
      before do
        visit vehicle_path(id: @vehicle.to_param)
      end
      
      it "shows the service date of the maintenance event" do
        expect(page).to have_text @vehicle_maintenance_event.service_date.to_s(:long)
      end
    end

    describe "GET /vehicles/:id/edit" do
      before do
        visit edit_vehicle_path(id: @vehicle.to_param)
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to delete the maintenance event", js: true do
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to edit the maintenance event", js: true do
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to add a new maintenance event", js: true do
      end
    end
  end
end
