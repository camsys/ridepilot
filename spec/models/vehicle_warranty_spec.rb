require 'rails_helper'

RSpec.describe VehicleWarranty, type: :model do
  it_behaves_like "an associable for a document" do
    before do
      @owner = create :vehicle
    end
  end
  
  it "requires a vehicle" do
    warranty = build :vehicle_warranty, vehicle: nil
    expect(warranty.valid?).to be_falsey
    expect(warranty.errors.keys).to include :vehicle
  end

  it "requires a description" do
    warranty = build :vehicle_warranty, description: nil
    expect(warranty.valid?).to be_falsey
    expect(warranty.errors.keys).to include :description
  end

  it "requires an expiration_date" do
    warranty = build :vehicle_warranty, expiration_date: nil
    expect(warranty.valid?).to be_falsey
    expect(warranty.errors.keys).to include :expiration_date
  end

  describe "#expired?" do
    it "knows if the record is considered expired" do
      warranty = build :vehicle_warranty, expiration_date: Date.current
      expect(warranty.expired?).to be_falsey

      warranty.expiration_date = Date.current.yesterday
      expect(warranty.expired?).to be_truthy
    end
  end

  describe ".expired" do
    before do
      @warranty_yesterday = create :vehicle_warranty, expiration_date: Date.current.yesterday
      @warranty_today = create :vehicle_warranty, expiration_date: Date.current
    end
        
    it "finds warranties that have expired as of today by default" do
      expired = VehicleWarranty.expired
      expect(expired).to include @warranty_yesterday
      expect(expired).not_to include @warranty_today
    end
  
    it "can find warranties that will expire as of a specific date" do
      expired = VehicleWarranty.expired as_of: Date.current.tomorrow
      expect(expired).to include @warranty_yesterday, @warranty_today
    end
  end
  
  # RADAR Not currently used, but will be by reports
  describe ".expiring_soon" do
    before do
      @warranty_today = create :vehicle_warranty, expiration_date: Date.current
      @warranty_tomorrow = create :vehicle_warranty, expiration_date: Date.current.tomorrow
      @warranty_later = create :vehicle_warranty, expiration_date: Date.current + 7.days
    end

    it "finds warranties expiring as of today through the next 6 days by default" do
      expiring_soon = VehicleWarranty.expiring_soon
      expect(expiring_soon).to include @warranty_today, @warranty_tomorrow
      expect(expiring_soon).to_not include @warranty_later
    end
    
    it "can find warranties expiring as of a specific date" do
      expiring_soon = VehicleWarranty.expiring_soon(as_of: Date.current.tomorrow)
      expect(expiring_soon).to_not include @warranty_today
      expect(expiring_soon).to include @warranty_tomorrow, @warranty_later
    end
    
    it "can find warranties expiring through a specific date" do
      expiring_soon = VehicleWarranty.expiring_soon(through: Date.current + 7.days)
      expect(expiring_soon).to include @warranty_today, @warranty_tomorrow, @warranty_later
    end
  end
end
