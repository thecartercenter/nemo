class AddGroupByTagToReport < ActiveRecord::Migration
  def change
    add_column :report_reports, :group_by_tag, :boolean, default: false, null: false
  end
end
