class ChangeFilterOnReportReportsToText < ActiveRecord::Migration
  def up
   change_column :report_reports, :filter, :text
  end

  def down
   change_column :report_reports, :filter, :string
  end
end
