class ChangeReportTypeToKind < ActiveRecord::Migration
  def up
    rename_column(:report_reports, :type, :kind)
  end

  def down
  end
end
