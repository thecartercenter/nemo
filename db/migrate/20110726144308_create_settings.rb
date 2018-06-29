class CreateSettings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :settings do |t|
      t.integer :settable_id
      t.string :value

      t.timestamps
    end
  end

  def self.down
    drop_table :settings
  end
end
