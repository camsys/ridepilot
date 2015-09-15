class SetInDistrictAsFalseInAddresses < ActiveRecord::Migration
  def change
    change_column :addresses, :in_district, :boolean, default: false
  end
end
