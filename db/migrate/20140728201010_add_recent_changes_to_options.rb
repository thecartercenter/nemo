class AddRecentChangesToOptions < ActiveRecord::Migration[4.2]
  def change
    add_column :options, :recent_changes, :text
  end
end
