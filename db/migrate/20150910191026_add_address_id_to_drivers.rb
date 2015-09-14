class AddAddressIdToDrivers < ActiveRecord::Migration
  def change
    add_reference :drivers, :address, index: true
  end
end
