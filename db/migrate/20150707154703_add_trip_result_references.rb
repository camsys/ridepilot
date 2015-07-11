class AddTripResultReferences < ActiveRecord::Migration
  def change
    add_reference :trips, :trip_result, index: true
  end
end
