class UpdateGroupingToUseNewGroupingAttributeClass < ActiveRecord::Migration
  def up
    remove_column :report_groupings, :name
    remove_column :report_groupings, :code
    remove_column :report_groupings, :join_tables
    add_column :report_groupings, :attrib_id, :integer
  end

  def down
  end
end
