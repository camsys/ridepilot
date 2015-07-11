class FlagOldTripResultColumns < ActiveRecord::Migration
  def change
    rename_column :trips, :trip_result, :trip_result_old
  end
end
