class RenameTallyReportClasses < ActiveRecord::Migration[4.2]
  def up
    execute("UPDATE report_reports SET type = 'Report::AnswerTallyReport' WHERE type = 'Report::QuestionAnswerTallyReport'")
    execute("UPDATE report_reports SET type = 'Report::ResponseTallyReport' WHERE type = 'Report::GroupedTallyReport'")
  end

  def down
  end
end
