class AddDisplayTypeToReportReport < ActiveRecord::Migration[4.2]
  def change
    add_column :report_reports, :display_type, :string, :default => "Table"
  end
end
