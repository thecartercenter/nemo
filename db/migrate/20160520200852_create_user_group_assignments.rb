class CreateUserGroupAssignments < ActiveRecord::Migration
  def change
    create_table :user_group_assignments do |t|
      t.references :user, index: true, foreign_key: true
      t.references :user_group, index: true, foreign_key: true

      t.timestamps null: false
    end
    add_index :user_group_assignments, [:user_id, :user_group_id], unique: true
  end
end
