require 'rails_helper'

RSpec.describe DriverHistory, type: :model do
  it_behaves_like "an associable for a document" do
    before do
      @owner = create :driver
    end
  end
  
  it "requires a driver" do
    history = build :driver_history, driver: nil
    expect(history.valid?).to be_falsey
    expect(history.errors.keys).to include :driver
  end

  it "requires an event name" do
    history = build :driver_history, event: nil
    expect(history.valid?).to be_falsey
    expect(history.errors.keys).to include :event
  end

  it "requires an event date" do
    history = build :driver_history, event_date: nil
    expect(history.valid?).to be_falsey
    expect(history.errors.keys).to include :event_date
  end

  it "requires an event date on or before today" do
    history = build :driver_history, event_date: Date.current.tomorrow
    expect(history.valid?).to be_falsey
    expect(history.errors.keys).to include :event_date

    history.event_date = Date.current
    expect(history.valid?).to be_truthy
  end
end
