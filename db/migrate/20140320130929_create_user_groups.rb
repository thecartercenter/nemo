class CreateUserGroups < ActiveRecord::Migration
  def change
    create_table :user_groups do |t|
      t.foreign_key :user_id, :null => false
      t.foreign_key :group_id, :null => false

      t.timestamps
    end
  end
end
