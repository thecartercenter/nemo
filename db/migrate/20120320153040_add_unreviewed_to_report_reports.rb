class AddUnreviewedToReportReports < ActiveRecord::Migration[4.2]
  def change
    add_column :report_reports, :unreviewed, :boolean, :default => false
  end
end
