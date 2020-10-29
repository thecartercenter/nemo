# frozen_string_literal: true

class RemoveKindFromReportReports < ActiveRecord::Migration[4.2]
  def up
    remove_column :report_reports, :kind
    Report::Report.all.each { |r| r.aggregation = Report::Aggregation.find_by(name: "Tally"); r.save(validate: false) }
  end

  def down
    add_column :report_reports, :kind, :string
  end
end
