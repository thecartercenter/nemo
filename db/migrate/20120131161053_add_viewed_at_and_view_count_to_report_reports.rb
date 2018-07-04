class AddViewedAtAndViewCountToReportReports < ActiveRecord::Migration[4.2]
  def self.up
    add_column :report_reports, :viewed_at, :datetime
    add_column :report_reports, :view_count, :integer, :default => 0
  end

  def self.down
    remove_column :report_reports, :view_count
    remove_column :report_reports, :viewed_at
  end
end
