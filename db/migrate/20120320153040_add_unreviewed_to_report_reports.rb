class AddUnreviewedToReportReports < ActiveRecord::Migration
  def change
    add_column :report_reports, :unreviewed, :boolean, :default => false
  end
end
