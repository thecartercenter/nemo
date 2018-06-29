class AddReportIndexOnViewCount < ActiveRecord::Migration[4.2]
  def change
    add_index :report_reports, [:view_count]
  end
end
