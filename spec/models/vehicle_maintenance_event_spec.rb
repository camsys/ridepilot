require "rails_helper"

RSpec.describe VehicleMaintenanceEvent, type: :model do
  it_behaves_like "an associable for a document" do
    before do
      @owner = create :vehicle
    end
  end
  
  it "requires a vehicle" do
    maintenance = build :vehicle_maintenance_event, vehicle: nil
    expect(maintenance.valid?).to be_falsey
    expect(maintenance.errors.keys).to include :vehicle
  end

  it "requires services_performed" do
    maintenance = build :vehicle_maintenance_event, services_performed: nil
    expect(maintenance.valid?).to be_falsey
    expect(maintenance.errors.keys).to include :services_performed
  end
  
  it "requires service_date" do
    maintenance = build :vehicle_maintenance_event, service_date: nil
    expect(maintenance.valid?).to be_falsey
    expect(maintenance.errors.keys).to include :service_date
  end
  
  it "requires service_date to be a real date" do
    maintenance = build :vehicle_maintenance_event, service_date: "13/13/13"
    expect(maintenance.valid?).to be_falsey
    expect(maintenance.errors.keys).to include :service_date

    maintenance.service_date = "12/12/12"
    expect(maintenance.valid?).to be_truthy
  end
end
