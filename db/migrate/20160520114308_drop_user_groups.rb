class DropUserGroups < ActiveRecord::Migration
  def change
    drop_table :user_groups
  end
end
