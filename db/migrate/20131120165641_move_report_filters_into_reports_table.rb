class MoveReportFiltersIntoReportsTable < ActiveRecord::Migration[4.2]
  def up
    add_column :report_reports, :filter, :string

    # copy, removing outer parenths
    execute("UPDATE report_reports r, search_searches s
      SET r.filter = REPLACE(CONCAT(SUBSTRING(s.str, 2, 5), '(', SUBSTRING(s.str, 7, LENGTH(s.str) - 7), ')'), ',', '|')
      WHERE r.filter_id=s.id")
  end

  def down
    remove_column :report_reports, :filter
  end
end
