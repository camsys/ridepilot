require 'rails_helper'

RSpec.describe RepeatingTrip, type: :model do
  it_behaves_like "a recurring ride coordinator scheduler"
    
  describe "#instantiate!" do
    # TODO Add some robust examples. This set of commits didn't change any of
    # the #instantiate! code, but it did include backfilling missing specs, so 
    # I added this as a placeholder.
    # Partially exercised by recurring_ride_coordinator_shared_examples.rb
    it "generates trips"
  end
end
