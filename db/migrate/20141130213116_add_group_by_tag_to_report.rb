class AddGroupByTagToReport < ActiveRecord::Migration[4.2]
  def change
    add_column :report_reports, :group_by_tag, :boolean, default: false, null: false
  end
end
