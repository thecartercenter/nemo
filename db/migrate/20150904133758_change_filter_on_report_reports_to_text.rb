class ChangeFilterOnReportReportsToText < ActiveRecord::Migration[4.2]
  def up
   change_column :report_reports, :filter, :text
  end

  def down
   change_column :report_reports, :filter, :string
  end
end
