class AddForeignKeyIndicesToAssignments < ActiveRecord::Migration[4.2]
  def change
    add_index :assignments, :mission_id
    add_index :assignments, :user_id
  end
end
