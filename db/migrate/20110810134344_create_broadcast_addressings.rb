class CreateBroadcastAddressings < ActiveRecord::Migration[4.2]
  def self.up
    create_table :broadcast_addressings do |t|
      t.integer :broadcast_id
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :broadcast_addressings
  end
end
