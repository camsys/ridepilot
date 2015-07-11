class AddServiceLevelReferences < ActiveRecord::Migration
  def change
    add_reference :trips, :service_level, index: true
    add_reference :customers, :service_level, index: true
  end
end
