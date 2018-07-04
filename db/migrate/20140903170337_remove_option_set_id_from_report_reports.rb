class RemoveOptionSetIdFromReportReports < ActiveRecord::Migration[4.2]
  def up
    remove_column :report_reports, :option_set_id
  end

  def down
    add_column :report_reports, :option_set_id, :integer
  end
end
