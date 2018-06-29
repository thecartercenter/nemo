class RemoveSearches < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key(:report_reports, :name => 'report_reports_filter_id_fk')
    remove_column :report_reports, :filter_id
    drop_table :search_searches
  end

  def down
  end
end
