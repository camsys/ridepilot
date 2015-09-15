class AddIsElderlyToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :is_elderly, :boolean, default: false
  end
end
