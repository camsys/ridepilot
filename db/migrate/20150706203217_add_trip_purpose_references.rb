class AddTripPurposeReferences < ActiveRecord::Migration
  def change
    add_reference :trips, :trip_purpose, index: true
    add_reference :repeating_trips, :trip_purpose, index: true
    add_reference :addresses, :trip_purpose, index: true
  end
end
