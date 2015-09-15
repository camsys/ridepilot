require 'rails_helper'

RSpec.describe DriverCompliance, type: :model do
  it_behaves_like "an associable for a document" do
    before do
      @owner = create :driver
    end
  end
  
  it_behaves_like "a compliance event"
  
  it_behaves_like "a recurring compliance event" do
    before do
      @owner_class = RecurringDriverCompliance

      # All model attributes that are note included in 
      # .editable_occurrence_attributes
      @unchangeable_attributes = [:event, :notes, :due_date]

      # Sample values for the attributes returned by 
      # .editable_occurrence_attributes
      @changeable_attributes = {compliance_date: Date.current}
    end
  end
  
  it "requires a driver" do
    compliance = build :driver_compliance, driver: nil
    expect(compliance.valid?).to be_falsey
    expect(compliance.errors.keys).to include :driver
  end

  it "requires a due date" do
    compliance = build :driver_compliance, due_date: nil
    expect(compliance.valid?).to be_falsey
    expect(compliance.errors.keys).to include :due_date
  end

  describe ".for_driver" do
    before do
      @driver_1 = create :driver
      @driver_2 = create :driver
      @for_driver_1 = create :driver_compliance, driver: @driver_1
      @for_driver_2 = create :driver_compliance, driver: @driver_2
    end
    
    it "finds compliance events for a specified driver or driver id" do
      expect(DriverCompliance.for_driver(@driver_1)).to include @for_driver_1
      expect(DriverCompliance.for_driver(@driver_1)).not_to include @for_driver_2
    end

    it "can find compliance events for an array of drivers or driver ids" do
      expect(DriverCompliance.for_driver([@driver_1, @driver_2])).to include @for_driver_1
      expect(DriverCompliance.for_driver([@driver_1, @driver_2])).to include @for_driver_2
    end
  end
  
  describe ".overdue" do
    it "finds compliance events overdue as of today by default" do
      compliance = create :driver_compliance, due_date: Date.current.yesterday
      expect(DriverCompliance.overdue).to include compliance
    end
  
    it "can find overdue compliance events as of a specific date" do
      compliance = create :driver_compliance, due_date: Date.current
      expect(DriverCompliance.overdue(as_of: Date.current.tomorrow)).to include compliance
    end
  end
  
  # RADAR Not currently used, but will be by reports
  describe ".due_soon" do
    before do
      @compliance_today = create :driver_compliance, due_date: Date.current
      @compliance_tomorrow = create :driver_compliance, due_date: Date.current.tomorrow
      @compliance_later = create :driver_compliance, due_date: Date.current + 7.days
    end

    it "finds items due as of today through the next 6 days by default" do
      compliances = DriverCompliance.due_soon
      expect(compliances).to include @compliance_today, @compliance_tomorrow
      expect(compliances).to_not include @compliance_later
    end
    
    it "can find items due as of a specific date" do
      compliances = DriverCompliance.due_soon(as_of: Date.current.tomorrow)
      expect(compliances).to_not include @compliance_today
      expect(compliances).to include @compliance_tomorrow, @compliance_later
    end
    
    it "can find items due through a specific date" do
      compliances = DriverCompliance.due_soon(through: Date.current + 7.days)
      expect(compliances).to include @compliance_today, @compliance_tomorrow, @compliance_later
    end
  end
end
