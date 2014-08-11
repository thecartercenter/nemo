class AddRecentChangesToOptions < ActiveRecord::Migration
  def change
    add_column :options, :recent_changes, :text
  end
end
