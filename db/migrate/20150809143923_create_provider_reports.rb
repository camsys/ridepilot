class CreateProviderReports < ActiveRecord::Migration
  def change
    create_table :provider_reports do |t|
      t.references :provider, index: true
      t.references :custom_report, index: true
      t.boolean :inactive

      t.timestamps
    end
  end
end
