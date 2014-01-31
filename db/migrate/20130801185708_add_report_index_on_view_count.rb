class AddReportIndexOnViewCount < ActiveRecord::Migration
  def change
    add_index :report_reports, [:view_count]
  end
end
