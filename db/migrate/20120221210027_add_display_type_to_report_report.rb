class AddDisplayTypeToReportReport < ActiveRecord::Migration
  def change
    add_column :report_reports, :display_type, :string, :default => "Table"
  end
end
