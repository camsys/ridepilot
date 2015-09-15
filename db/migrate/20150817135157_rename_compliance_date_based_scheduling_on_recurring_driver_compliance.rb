class RenameComplianceDateBasedSchedulingOnRecurringDriverCompliance < ActiveRecord::Migration
  def change
    rename_column :recurring_driver_compliances, :compliance_date_based_scheduling, :compliance_based_scheduling
  end
end