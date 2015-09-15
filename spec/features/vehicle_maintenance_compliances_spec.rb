require "rails_helper"

RSpec.describe "VehicleMaintenanceCompliances" do
  context "for admin" do
    before :each do
      @admin = create(:admin)
      visit new_user_session_path
      fill_in 'Email', :with => @admin.email
      fill_in 'Password', :with => @admin.password
      click_button 'Log In'
      
      @vehicle = create :vehicle, :provider => @admin.current_provider
      @vehicle_maintenance_compliance = create :vehicle_maintenance_compliance, :complete, vehicle: @vehicle
    end
    
    it_behaves_like "it accepts nested attributes for document associations" do
      before do
        @owner = @vehicle
        @example = @vehicle_maintenance_compliance
      end
    end

    describe "GET /vehicles/:id" do
      it "shows the name of the compliance event" do
        visit vehicle_path(id: @vehicle.to_param)
        expect(page).to have_text @vehicle_maintenance_compliance.event
      end
      
      it "shows the due date of the compliance event for due_type 'date'" do
        visit vehicle_path(id: @vehicle.to_param)
        expect(page).to have_text @vehicle_maintenance_compliance.due_date.to_s(:long)
      end
      
      it "shows the due mileage of the compliance event for due_type 'mileage'" do
        @vehicle_maintenance_compliance.update_attributes due_type: "mileage", due_mileage: 100
        visit vehicle_path(id: @vehicle.to_param)
        expect(page).to have_text "100 mi"
      end
      
      it "shows the due date and due mileage of the compliance event for due_type 'both'" do
        @vehicle_maintenance_compliance.update_attributes due_type: "both", due_mileage: 100
        visit vehicle_path(id: @vehicle.to_param)
        expect(page).to have_text "#{@vehicle_maintenance_compliance.due_date.to_s(:long)} and 100 mi"
      end
      
      it "shows the compliance date of the compliance event" do
        visit vehicle_path(id: @vehicle.to_param)
        expect(page).to have_text @vehicle_maintenance_compliance.compliance_date.to_s(:long)
      end
    end

    describe "GET /vehicles/:id/edit" do
      before do
        visit edit_vehicle_path(id: @vehicle.to_param)
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to delete the compliance event", js: true do
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to edit the compliance event", js: true do
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to add a new compliance event", js: true do
      end
    end
  end
end
