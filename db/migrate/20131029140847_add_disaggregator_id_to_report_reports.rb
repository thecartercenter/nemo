class AddDisaggregatorIdToReportReports < ActiveRecord::Migration
  def change
    add_column :report_reports, :disaggregator_id, :integer, :null => true
    add_foreign_key :report_reports, :questionings, :column => 'disaggregator_id' 
  end
end
