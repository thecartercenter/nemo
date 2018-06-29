class CreateGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :groups do |t|
      t.string :name, :null => false
      t.integer :mission_id, :null => false
      t.foreign_key :missions

      t.timestamps
    end
  end
end
