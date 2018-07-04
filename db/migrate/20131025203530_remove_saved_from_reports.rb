class RemoveSavedFromReports < ActiveRecord::Migration[4.2]
  def up
    remove_column :report_reports, :saved
  end

  def down
  end
end
