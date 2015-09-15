class CreateServiceLevels < ActiveRecord::Migration
  def change
    create_table :service_levels do |t|
      t.string :name

      t.timestamps
    end
  end
end
