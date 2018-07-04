class RemoveRecentChangesFromOptions < ActiveRecord::Migration[4.2]
  def up
    remove_column :options, :recent_changes
  end

  def down
    add_column :options, :recent_changes, :text
  end
end
