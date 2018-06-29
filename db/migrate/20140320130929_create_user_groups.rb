class CreateUserGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :user_groups do |t|
      t.integer :user_id, :null => false
      t.integer :group_id, :null => false
      t.foreign_key :users
      t.foreign_key :groups

      t.timestamps
    end
  end
end
