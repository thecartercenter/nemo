class RenameReportFields < ActiveRecord::Migration[4.2]
  def change
    rename_column :report_reports, :grouping1_id, :pri_group_by_id
    rename_column :report_reports, :grouping2_id, :sec_group_by_id
    remove_column :report_reports, :aggregation_id
    add_column :report_reports, :aggregation_name, :string
  end
end
