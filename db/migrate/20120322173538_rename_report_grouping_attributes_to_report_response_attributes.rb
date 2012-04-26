class RenameReportGroupingAttributesToReportResponseAttributes < ActiveRecord::Migration
  def up
    rename_table :report_grouping_attributes, :report_response_attributes
  end

  def down
    rename_table :report_response_attributes, :report_grouping_attributes
  end
end
