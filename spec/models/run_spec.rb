require "rails_helper"

RSpec.describe Run, type: :model do
  it_behaves_like "a recurring ride coordinator" do
    before do
      # These options reflect the concern setup method:
      # schedules_occurrences_with :repeating_run
      @occurrence_scheduler_association = :repeating_run
      
      # To help us know what attribute to check occurrence dates against
      @occurrence_date_attribute = :date
    end
  end

  describe "set_complete" do
    it "is called before validation" do
      run = build :run
      expect(run).to receive(:set_complete)
      run.valid?
    end
    
    it "checks for any pending trips" do
      run = create :run, actual_start_time: 15.minutes.ago.in_time_zone, actual_end_time: Time.zone.now
      trip = create :trip, run: run, trip_result: nil
      run.valid?
      expect(run.complete?).to be_falsey
      
      trip.update_attributes trip_result: create(:trip_result)
      run.valid?
      expect(run.complete?).to be_truthy
    end
    
    it "checks to see if #actual_end_time is before 'now'" do
      run = create :run, actual_start_time: 15.minutes.ago.in_time_zone, actual_end_time: nil
      run.valid?
      expect(run.complete?).to be_falsey
      
      run.actual_end_time = 5.minutes.from_now.in_time_zone
      run.valid?
      expect(run.complete?).to be_falsey
      
      run.actual_end_time = 5.minutes.ago.in_time_zone
      run.valid?
      expect(run.complete?).to be_truthy
    end
    
    it "uses the Provider#fields_required_for_run_completion to decide if a run is considered complete" do
      run = create :run, actual_start_time: 15.minutes.ago.in_time_zone, actual_end_time: Time.zone.now
      run.provider.update_attributes fields_required_for_run_completion: %w(start_odometer)
      run.valid?
      expect(run.complete?).to be_falsey
      
      run.start_odometer = 1
      run.valid?
      expect(run.complete?).to be_truthy
    end
  end
end
