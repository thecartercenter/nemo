class WhitelistPolymorphicTable < ActiveRecord::Migration
  def up
    create_table :whitelists do |t|
      t.integer :user_id
      t.integer :whitelistable_id
      t.string  :whitelistable_type
      t.timestamps
    end
  end

  def down
    drop_table :whitelists
  end
end
