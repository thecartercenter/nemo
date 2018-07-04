class CreateOptionSettings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :option_settings do |t|
      t.integer :option_id
      t.integer :option_set_id

      t.timestamps
    end
  end

  def self.down
    drop_table :option_settings
  end
end
