class AddTitleToCustomReports < ActiveRecord::Migration
  def change
    add_column :custom_reports, :title, :string
  end
end
