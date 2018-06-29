class AddDisaggregatorIdToReportReports < ActiveRecord::Migration[4.2]
  def change
    add_column :report_reports, :disagg_qing_id, :integer, :null => true
    add_foreign_key :report_reports, :questionings, :column => 'disagg_qing_id'
  end
end
