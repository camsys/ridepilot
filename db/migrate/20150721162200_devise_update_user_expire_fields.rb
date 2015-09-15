class DeviseUpdateUserExpireFields < ActiveRecord::Migration
 def change
  add_column :users, :expires_at, :datetime
 end
end