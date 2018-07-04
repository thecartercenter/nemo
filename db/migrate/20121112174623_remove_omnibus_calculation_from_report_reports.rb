class RemoveOmnibusCalculationFromReportReports < ActiveRecord::Migration[4.2]
  def change
    remove_column :report_reports, :omnibus_calculation
  end
end
