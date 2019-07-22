# frozen_string_literal: true

class RemoveReportOptSetChoiceDuplicates < ActiveRecord::Migration[5.2]
  def up
    result = execute("SELECT (ARRAY_AGG(id))[1] AS id, option_set_id, report_report_id, COUNT(*) AS num
      FROM report_option_set_choices GROUP BY option_set_id, report_report_id HAVING COUNT(*) > 1")
    result.to_a.each do |row|
      execute("DELETE FROM report_option_set_choices WHERE id != '#{row['id']}' AND
        option_set_id = '#{row['option_set_id']}' AND report_report_id = '#{row['report_report_id']}'")
    end
  end
end
