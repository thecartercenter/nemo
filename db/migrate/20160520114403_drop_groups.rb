class DropGroups < ActiveRecord::Migration[4.2]
  def change
    drop_table :groups
  end
end
