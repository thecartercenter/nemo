class RemoveKindFromReportReports < ActiveRecord::Migration
  def up
    remove_column :report_reports, :kind
    Report::Report.all.each{|r| r.update_attributes!(:aggregation => Report::Aggregation.find_by_name("Tally"))}
  end

  def down
    add_column :report_reports, :kind, :string
  end
end
