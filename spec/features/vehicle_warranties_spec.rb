require "rails_helper"

RSpec.describe "VehicleWarranties" do
  context "for admin" do
    before :each do
      @admin = create(:admin)
      visit new_user_session_path
      fill_in 'Email', :with => @admin.email
      fill_in 'Password', :with => @admin.password
      click_button 'Log In'
      
      @vehicle = create :vehicle, :provider => @admin.current_provider
      @vehicle_warranty = create :vehicle_warranty, vehicle: @vehicle
    end
    
    it_behaves_like "it accepts nested attributes for document associations" do
      before do
        @owner = @vehicle
        @example = @vehicle_warranty
      end
    end

    describe "GET /vehicles/:id" do
      it "shows the description of the warranty" do
        visit vehicle_path(id: @vehicle.to_param)
        expect(page).to have_text @vehicle_warranty.description
      end
      
      it "shows the expiration date of the warranty" do
        visit vehicle_path(id: @vehicle.to_param)
        expect(page).to have_text @vehicle_warranty.expiration_date.to_s(:long)
      end
    end

    describe "GET /vehicles/:id/edit" do
      before do
        visit edit_vehicle_path(id: @vehicle.to_param)
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to delete the warranty", js: true do
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to edit the warranty", js: true do
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to add a new warranty", js: true do
      end
    end
  end
end
