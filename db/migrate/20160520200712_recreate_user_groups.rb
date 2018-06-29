class RecreateUserGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :user_groups do |t|
      t.string :name, null: false
      t.references :mission, index: true, foreign_key: true

      t.timestamps null: false
    end
    add_index :user_groups, [:name, :mission_id], unique: true
  end
end
