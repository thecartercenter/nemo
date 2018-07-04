class CreateAssignments < ActiveRecord::Migration[4.2]
  def change
    create_table :assignments do |t|
      t.integer :mission_id
      t.integer :user_id
      t.integer :role_id
      t.boolean :active

      t.timestamps
    end
  end
end
