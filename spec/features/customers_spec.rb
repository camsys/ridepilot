require "rails_helper"

RSpec.describe "Customers" do
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
    
    describe "DELETE /customer/:id" do
      attr_reader :customer
      
      before do
        @customer = create :customer, :provider => user.current_provider
      end
      
      context "when the customer has trips" do
        attr_reader :trips
        
        before do
          @trips = (1..5).map { create :trip, :customer => customer }
        end
        
        context "when customer_id is present" do
          attr_reader :other
          
          before do
            @other = create :customer, :provider => user.current_provider
          end
          
          it "redirects to other customer" do
            skip "redirecting to sign in for some reason" 
            
            delete customer_path(@customer, :customer_id => other.id)
            expect(rendered).to redirect_to(customer_path(other))
          end
        end
        
        context "when customer_id is not present" do
          it "renders show with an error" do
            skip "redirecting to sign in for some reason" 
            
            delete customer_path(@customer)
            expect(page.has_content?("could not be deleted")).to be
          end
        end
      end
      
      context "when the customer does not have trips" do
        it "redirects to customer index" do
          skip "redirecting to sign in for some reason" 
          
          delete customer_path(@customer)
          expect(rendered).to redirect_to(customers_path)
        end
      end
    end
  end
  
  context "for editor" do
    attr_reader :user

    before do
      @user = create(:role, :level => 50).user
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
        end
        
        it "does not show delete link" do
          visit customer_path(@customer)
          expect(page.has_link?("Delete")).not_to be
        end
      end
      
      context "when the customer has no associated trips" do
        before do
          @customer = create :customer, :provider => user.current_provider
        end
        
        it "shows the delete link" do
          visit customer_path(@customer)
          expect(page.has_link?("Delete")).to be
        end
      end
    end
    
    describe "DELETE /customer/:id" do
      attr_reader :customer
      
      before do
        @customer = create :customer, :provider => user.current_provider
      end
      
      it "redirects to customer index" do
        skip "redirecting to sign in for some reason" 
        
        delete customer_path(@customer)
        expect(rendered).to redirect_to(customers_path)
      end
    end
  end
end
