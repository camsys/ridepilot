require "rails_helper"

RSpec.describe "DriverHistories" do
  context "for admin" do
    before :each do
      @admin = create(:admin)
      visit new_user_session_path
      fill_in 'Email', :with => @admin.email
      fill_in 'Password', :with => @admin.password
      click_button 'Log In'
      
      @driver = create :driver, :provider => @admin.current_provider
      @driver_history = create :driver_history, driver: @driver
    end
    
    it_behaves_like "it accepts nested attributes for document associations" do
      before do
        @owner = @driver
        @example = @driver_history
      end
    end

    describe "GET /drivers/:id" do
      before do
        visit driver_path(id: @driver.to_param)
      end
      
      it "shows the name of the history event" do
        expect(page).to have_text @driver_history.event
      end
      
      it "shows the date of the history event" do
        expect(page).to have_text @driver_history.event_date.to_s(:long)
      end
    end

    describe "GET /drivers/:id/edit" do
      before do
        visit edit_driver_path(id: @driver.to_param)
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to delete the history event", js: true do
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to edit the history event", js: true do
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to add a new history event", js: true do
      end
    end
  end
end
