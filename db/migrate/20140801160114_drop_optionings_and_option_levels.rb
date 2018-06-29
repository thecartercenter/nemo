class DropOptioningsAndOptionLevels < ActiveRecord::Migration[4.2]
  def up
    drop_table :optionings
    drop_table :option_levels
  end

  def down
  end
end
