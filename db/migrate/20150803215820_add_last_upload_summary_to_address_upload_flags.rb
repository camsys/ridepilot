class AddLastUploadSummaryToAddressUploadFlags < ActiveRecord::Migration
  def change
    add_column :address_upload_flags, :last_upload_summary, :text
  end
end
