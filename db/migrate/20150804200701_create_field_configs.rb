class CreateFieldConfigs < ActiveRecord::Migration
  def change
    create_table :field_configs do |t|
      t.references :provider, index: true, null: false
      t.string :table_name, null: false
      t.string :field_name, null: false
      t.boolean :visible, default: true
      t.boolean :required, default: false

      t.timestamps
    end
  end
end
