require "rails_helper"

RSpec.describe Customer do
  describe "service_level_id" do
    it "should be an integer field" do
      c = Customer.new
      expect(c).to respond_to(:service_level_id)
      c.service_level_id = "1"
      expect(c.service_level_id).to eq 1
      c.service_level_id = "0"
      expect(c.service_level_id).to eq 0
    end
  end
  
  describe "default_funding_source_id" do
    it "should be an integer field" do
      c = Customer.new
      expect(c).to respond_to(:default_funding_source_id)
      c.default_funding_source_id = "1"
      expect(c.default_funding_source_id).to eq 1
      c.default_funding_source_id = "0"
      expect(c.default_funding_source_id).to eq 0
    end
  end
  
  describe "ada_eligible" do
    it "should be a boolean field" do
      c = Customer.new
      expect(c).to respond_to(:ada_eligible)
      c.ada_eligible = "1"
      expect(c.ada_eligible).to be_truthy
      c.ada_eligible = "0"
      expect(c.ada_eligible).to be_falsey
    end
  end
  
  describe "medicaid_eligible" do
    it "should be a boolean field" do
      c = Customer.new
      expect(c).to respond_to(:medicaid_eligible)
      c.medicaid_eligible = "1"
      expect(c.medicaid_eligible).to be_truthy
      c.medicaid_eligible = "0"
      expect(c.medicaid_eligible).to be_falsey
    end
  end
  
  describe "prime_number" do
    it "should be a string field" do
      c = Customer.new
      expect(c).to respond_to(:prime_number)
      c.prime_number = "abc"
      expect(c.prime_number).to eq("abc")
    end
  end
  
  describe "replace_with!" do
    context "when no customer id" do
      attr_reader :customer
      
      before do
        @customer = create :customer
      end
      
      it "is false" do
        expect(@customer.replace_with!("")).not_to be
      end
    end
    
    context "when invalid customer id" do
      attr_reader :customer
      
      before do
        @customer = create :customer
      end
      
      it "is false" do
        expect(@customer.replace_with!(-1)).not_to be
      end
    end
    
    context "when valid customer id" do
      context "when customer has trips" do
        attr_reader :customer, :trips, :other

        before do
          @customer = create :customer
          @trips    = (1..5).map { create :trip, :customer => customer }
          @other    = create :customer
          
          customer.replace_with!(other.id)
        end
        
        it "destroys self" do
          expect(Customer.exists?(customer.id)).not_to be
        end

        it "moves self's trips to other customer" do
          for trip in trips
            expect(trip.reload.customer).to eq(other)
          end
        end
      end
      
      context "when customer has no trips" do
        attr_reader :customer

        before do
          @customer = create :customer
        end
        
        it "destroys self" do

        end
      end
      
      context "when other_customer_id is the same as customer.id" do
        before do
          @customer = create :customer
          @other_customer = create :customer
        end
        
        it "should return false" do
          expect(@customer.replace_with!(@customer.id)).to be_falsey
          expect(@customer.replace_with!(@other_customer.id)).not_to be_falsey
        end
      end
    end
  end
end
