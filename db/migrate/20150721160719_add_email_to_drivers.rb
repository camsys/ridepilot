class AddEmailToDrivers < ActiveRecord::Migration
  def change
    add_column :drivers, :email, :string
  end
end
