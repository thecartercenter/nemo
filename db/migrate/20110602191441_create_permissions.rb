class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.string :controller
      t.string :action
      t.integer :role_id

      t.timestamps
    end
  end

  def self.down
    drop_table :permissions
  end
end
