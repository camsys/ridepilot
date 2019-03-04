class AddIs5310ReportableToVehicles < ActiveRecord::Migration[5.2]
  def change
    add_column :vehicles, :is_5310_reportable, :boolean, default: true
  end
end
