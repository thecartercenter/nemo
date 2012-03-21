class AddPercentagesToReportReports < ActiveRecord::Migration
  def change
    add_column :report_reports, :percent_type, :string
  end
end
