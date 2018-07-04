class DropUserGroups < ActiveRecord::Migration[4.2]
  def change
    drop_table :user_groups
  end
end
