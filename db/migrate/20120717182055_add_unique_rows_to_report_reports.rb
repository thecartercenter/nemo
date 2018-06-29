class AddUniqueRowsToReportReports < ActiveRecord::Migration[4.2]
  def change
    add_column :report_reports, :unique_rows, :boolean
  end
end
