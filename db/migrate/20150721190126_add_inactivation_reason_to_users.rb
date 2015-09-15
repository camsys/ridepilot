class AddInactivationReasonToUsers < ActiveRecord::Migration
  def change
    add_column :users, :inactivation_reason, :string
  end
end
