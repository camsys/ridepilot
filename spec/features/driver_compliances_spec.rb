require "rails_helper"

RSpec.describe "DriverCompliances" do
  context "for admin" do
    before :each do
      @admin = create(:admin)
      visit new_user_session_path
      fill_in 'Email', :with => @admin.email
      fill_in 'Password', :with => @admin.password
      click_button 'Log In'
      
      @driver = create :driver, :provider => @admin.current_provider
      @driver_compliance = create :driver_compliance, driver: @driver, compliance_date: Date.current
    end
    
    it_behaves_like "it accepts nested attributes for document associations" do
      before do
        @owner = @driver
        @example = @driver_compliance
      end
    end

    describe "GET /drivers/:id" do
      before do
        visit driver_path(id: @driver.to_param)
      end
      
      it "shows the name of the compliance event" do
        expect(page).to have_text @driver_compliance.event
      end
      
      it "shows the due date of the compliance event" do
        expect(page).to have_text @driver_compliance.due_date.to_s(:long)
      end
      
      it "shows the compliance date of the compliance event" do
        expect(page).to have_text @driver_compliance.compliance_date.to_s(:long)
      end
    end

    describe "GET /drivers/:id/edit" do
      before do
        visit edit_driver_path(id: @driver.to_param)
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
