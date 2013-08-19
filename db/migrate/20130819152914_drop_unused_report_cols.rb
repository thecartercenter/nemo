class DropUnusedReportCols < ActiveRecord::Migration
  def up
  	remove_column :report_reports, :pri_group_by_id
  	remove_column :report_reports, :sec_group_by_id
  	remove_column :report_reports, :show_question_labels
  end

  def down
  end
end
