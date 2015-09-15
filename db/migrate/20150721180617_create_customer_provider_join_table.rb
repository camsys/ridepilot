class CreateCustomerProviderJoinTable < ActiveRecord::Migration
  def change
    create_table :customers_providers, :id => false do |t|
        t.references :provider
        t.references :customer
    end
    add_index :customers_providers, [:customer_id, :provider_id]
    add_index :customers_providers, :customer_id
    add_index :customers_providers, :provider_id
  end
end
