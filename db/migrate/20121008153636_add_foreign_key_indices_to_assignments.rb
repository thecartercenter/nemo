class AddForeignKeyIndicesToAssignments < ActiveRecord::Migration
  def change
    add_index :assignments, :mission_id
    add_index :assignments, :user_id
  end
end
