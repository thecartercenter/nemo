class RemoveOmnibusCalculationFromReportReports < ActiveRecord::Migration
  def change
    remove_column :report_reports, :omnibus_calculation
  end
end
