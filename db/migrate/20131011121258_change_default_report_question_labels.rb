class ChangeDefaultReportQuestionLabels < ActiveRecord::Migration
  def up
    change_column :report_reports, :question_labels, :string, :default => "title"
  end

  def down
  end
end
