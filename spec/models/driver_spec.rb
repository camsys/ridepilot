require "rails_helper"

RSpec.describe Driver, type: :model do
  it "requires a provider" do
    driver = build :driver, provider: nil
    expect(driver.valid?).to be_falsey
    expect(driver.errors.keys).to include :provider
  end

  it "requires a user" do
    driver = build :driver, user: nil
    expect(driver.valid?).to be_falsey
    expect(driver.errors.keys).to include :user
  end

  it "cannot be linked to the same user as another driver" do
    driver_1 = create :driver
    driver_2 = build :driver, user: driver_1.user
    expect(driver_2.valid?).to be_falsey
    expect(driver_2.errors.keys).to include :user_id

    driver_2.user = create :user
    expect(driver_2.valid?).to be_truthy
  end

  it "must have a unique name within the scope of its provider" do
    driver_1 = create :driver
    driver_2 = build :driver, name: driver_1.name, provider: driver_1.provider
    expect(driver_2.valid?).to be_falsey
    expect(driver_2.errors.keys).to include :name

    driver_2.provider = create :provider
    expect(driver_2.valid?).to be_truthy
  end

  it "must have a name at least 2 characters in length" do
    driver = build :driver, name: "M"
    expect(driver.valid?).to be_falsey
    expect(driver.errors.keys).to include :name

    driver.name = "Mo"
    expect(driver.valid?).to be_truthy
  end

  it "must have a valid email when specified" do
    driver = build :driver, email: "m@m"
    expect(driver.valid?).to be_falsey
    expect(driver.errors.keys).to include :email

    driver.email = "m@m.m"
    expect(driver.valid?).to be_truthy
  end

  it "can find drivers for a given provider" do
    driver_1 = create :driver
    driver_2 = create :driver
    drivers = Driver.for_provider driver_1.provider
    expect(drivers).to include driver_1
    expect(drivers).not_to include driver_2
  end

  it "can find drivers who are not assigned to a device pool" do
    provider = create :provider
    driver_1 = create :driver, provider: provider
    driver_2 = create :driver, provider: provider
    create :device_pool_driver, driver: driver_1, device_pool: create(:device_pool, provider: provider)
    unassigned = Driver.unassigned provider
    expect(unassigned).not_to include driver_1
    expect(unassigned).to include driver_2
  end
  
  it "can generate a hash of the driver's operating hours" do
    driver = create :driver
    hours = create :operating_hours, driver: driver, day_of_week: 0, start_time: "01:00", end_time: "02:00"
    expect(driver.hours_hash[0]).to eql hours
  end
  
  describe "available?" do
    before do
      @driver = create :driver
      @day_of_week = 0
      @time_of_day = "15:30"
    end
    
    it "returns true if no operating hours are defined" do
      expect(@driver.available?).to be_truthy
    end
    
    it "returns false if operating hours are defined, but not for that day" do
      create :operating_hours, driver: @driver, day_of_week: @day_of_week + 1
      expect(@driver.available?(@day_of_week, @time_of_day)).to be_falsey
    end
    
    it "returns true if the driver is available 24 hours" do
      create :operating_hours, driver: @driver, day_of_week: @day_of_week, start_time: "00:00", end_time: "00:00"
      expect(@driver.available?(@day_of_week, @time_of_day)).to be_truthy
    end
    
    it "returns false if the driver is not available that day" do
      create :operating_hours, driver: @driver, day_of_week: @day_of_week, start_time: nil, end_time: nil
      expect(@driver.available?(@day_of_week, @time_of_day)).to be_falsey
    end
    
    it "can check against regular hours" do
      hours = create :operating_hours, driver: @driver, day_of_week: @day_of_week, start_time: "12:00", end_time: "16:00"
      expect(@driver.available?(@day_of_week, @time_of_day)).to be_truthy
      
      hours.update_attributes end_time: "15:00"
      expect(@driver.available?(@day_of_week, @time_of_day)).to be_falsey
    end
    
    it "can check against irregular hours" do
      hours = create :operating_hours, driver: @driver, day_of_week: @day_of_week, start_time: "12:00", end_time: "00:30"
      expect(@driver.available?(@day_of_week, @time_of_day)).to be_truthy
      
      hours.update_attributes start_time: "16:00"
      expect(@driver.available?(@day_of_week, @time_of_day)).to be_falsey
    end
  end
  
  describe "driver_histories" do
    before do
      @driver = create :driver
    end
    
    it "destroys driver histories when the driver is destroyed" do
      3.times { create :driver_history, driver: @driver }
      expect {
        @driver.destroy
      }.to change(DriverHistory, :count).by(-3)
    end
  end
  
  describe "driver_compliances" do
    before do
      @driver = create :driver
    end
    
    it "destroys driver compliances when the driver is destroyed" do
      3.times { create :driver_compliance, driver: @driver }
      expect {
        @driver.destroy
      }.to change(DriverCompliance, :count).by(-3)
    end
  end
  
  describe "compliant?" do
    before do
      @driver = create :driver
    end

    it "returns true when a driver has no compliance entries" do
      expect(@driver.compliant?).to be_truthy
    end

    it "returns true when a driver's compliance entries are all complete" do
      create :driver_compliance, driver: @driver, due_date: Date.current.yesterday, compliance_date: Date.current
      expect(@driver.compliant?).to be_truthy
    end

    it "returns true when a driver's incomplete compliance entries are all due in the future" do
      create :driver_compliance, driver: @driver, due_date: Date.current.tomorrow
      expect(@driver.compliant?).to be_truthy
    end
    
    it "returns false when a driver has over due compliance entries" do
      create :driver_compliance, driver: @driver, due_date: Date.current.yesterday
      expect(@driver.compliant?).to be_falsey
    end
  end
  
  describe "documents" do
    before do
      @driver = create :driver
    end

    it "destroys documents when the driver is destroyed" do
      3.times { create :document, documentable: @driver }
      expect {
        @driver.destroy
      }.to change(Document, :count).by(-3)
    end
  end
end
