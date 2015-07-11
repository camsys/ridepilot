require "rails_helper"

RSpec.describe "Reports" do
  context "for admin" do
    attr_reader :user

    before :each do
      @user = create(:admin)
      visit new_user_session_path
      fill_in 'user_email', :with => user.email
      fill_in 'Password', :with => 'password#1'
      click_button 'Log In'
    end
    
    describe "GET /customer/:id" do
      attr_reader :customer
      
      context "when the customer has associated trips" do
        attr_reader :trips
        
        before do
          @customer = create :customer, :provider => user.current_provider
          @trips    = (1..5).map { create :trip, :customer => customer }
          visit customer_path(@customer)
        end
        
        it "shows duplicate link" do
          expect(page.has_link?("Duplicate")).to be
        end
        
        it "renders the duplicate customer dialog" do
          expect(page.has_selector?("#confirm-destroy", visible: false)).to be
        end
      end
      
      context "when the customer has no associated trips" do
        before do
          @customer = create :customer, :provider => user.current_provider
        end
        
        it "shows delete link" do
          visit customer_path(@customer)
          expect(page.has_link?("Delete")).to be
        end
      end
    end
  end
end
