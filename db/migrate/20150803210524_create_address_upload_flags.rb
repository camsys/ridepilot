class CreateAddressUploadFlags < ActiveRecord::Migration
  def change
    create_table :address_upload_flags do |t|
      t.boolean :is_loading, default: false
      t.references :provider, index: true

      t.timestamps
    end
  end
end
