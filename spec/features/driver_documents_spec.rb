require "rails_helper"

RSpec.describe "DriverDocuments" do
  context "for admin" do
    before do
      @admin = create(:admin)
      visit new_user_session_path
      fill_in 'Email', :with => @admin.email
      fill_in 'Password', :with => @admin.password
      click_button 'Log In'
      
      @driver = create :driver, :provider => @admin.current_provider
      @document = create :document, documentable: @driver
    end
    
    describe "GET /drivers/:id" do
      before do
        visit driver_path(id: @driver.to_param)
      end
      
      it "shows the uploaded date of the document" do
        expect(page).to have_text @document.document_updated_at.to_s(:long)
      end
      
      it "shows the description of the document" do
        expect(page).to have_text @document.description
      end
      
      it "shows a direct link to the uploaded file" do
        expect(page).to have_link "Download", href: @document.document.url
      end
    end

    describe "GET /drivers/:id/edit" do
      before do
        visit edit_driver_path(id: @driver.to_param)
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to delete the document", js: true do
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to edit the document", js: true do
      end
      
      # TODO Pending acceptance and merge of capybara_js branch into develop
      skip "shows a link to add a new document", js: true do
      end
    end
  end
end
