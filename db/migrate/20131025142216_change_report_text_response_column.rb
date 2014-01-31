class ChangeReportTextResponseColumn < ActiveRecord::Migration
  def up
    remove_column :report_reports, :show_long_responses
    add_column :report_reports, :text_responses, :string
  end
end
