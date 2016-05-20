class RecreateUserGroups < ActiveRecord::Migration
  def change
    create_table :user_groups do |t|
      t.string :name
      t.references :mission, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
