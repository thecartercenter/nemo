class DropOldReportTables < ActiveRecord::Migration[4.2]
  def up
    drop_table :report_aggregations
    drop_table :report_calculations
    drop_table :report_fields
    drop_table :report_groupings
    drop_table :report_reports
    drop_table :report_response_attributes
  end

  def down
  end
end
