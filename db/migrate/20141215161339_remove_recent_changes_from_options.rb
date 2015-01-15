class RemoveRecentChangesFromOptions < ActiveRecord::Migration
  def up
    remove_column :options, :recent_changes
  end

  def down
    add_column :options, :recent_changes, :text
  end
end
