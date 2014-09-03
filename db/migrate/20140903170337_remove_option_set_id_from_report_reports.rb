class RemoveOptionSetIdFromReportReports < ActiveRecord::Migration
  def up
    remove_column :report_reports, :option_set_id
  end

  def down
    add_column :report_reports, :option_set_id, :integer
  end
end
