class RemoveSavedFromReports < ActiveRecord::Migration
  def up
    remove_column :report_reports, :saved
  end

  def down
  end
end
