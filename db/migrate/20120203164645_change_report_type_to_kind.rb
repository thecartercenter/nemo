class ChangeReportTypeToKind < ActiveRecord::Migration[4.2]
  def up
    rename_column(:report_reports, :type, :kind)
  end

  def down
  end
end
