class AddUniqueRowsToReportReports < ActiveRecord::Migration
  def change
    add_column :report_reports, :unique_rows, :boolean
  end
end
