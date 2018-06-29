class AddStandardFormReportFieldsToReport < ActiveRecord::Migration[4.2]
  def change
    add_column :report_reports, :form_id, :integer, :null => true
    add_column :report_reports, :question_order, :string, :null => false, :default => 'number'
    add_column :report_reports, :show_long_responses, :boolean, :null => false, :default => true
    add_foreign_key :report_reports, :forms
  end
end
