class AddCreatorIdToReportReports < ActiveRecord::Migration[4.2]
  def change
    add_column :report_reports, :creator_id, :integer
    add_foreign_key :report_reports, :users, column: :creator_id, dependent: :nullify
  end
end
