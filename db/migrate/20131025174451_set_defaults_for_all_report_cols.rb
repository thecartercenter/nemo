class SetDefaultsForAllReportCols < ActiveRecord::Migration[4.2]
  def up
    change_column :report_reports, :unique_rows, :boolean, :default => false
    change_column :report_reports, :text_responses, :string, :default => 'all'
  end

  def down
  end
end
