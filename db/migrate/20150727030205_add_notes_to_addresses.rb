class AddNotesToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :notes, :text
    change_column :translations, :value, :text rescue nil
  end
end
