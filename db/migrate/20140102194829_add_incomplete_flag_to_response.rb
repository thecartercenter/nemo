class AddIncompleteFlagToResponse < ActiveRecord::Migration
  def change
    add_column :responses, :incomplete, :boolean, :default => false, :null => false
  end

  def down
    remove_column :responses, :incomplete, :boolean
  end
end
