class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name, :null => false
      t.foreign_key :mission_id, :null => false

      t.timestamps
    end
  end
end
