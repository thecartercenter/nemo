class AddPercentagesToReportReports < ActiveRecord::Migration[4.2]
  def change
    add_column :report_reports, :percent_type, :string
  end
end
