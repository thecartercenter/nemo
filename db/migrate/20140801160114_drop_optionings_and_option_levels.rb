class DropOptioningsAndOptionLevels < ActiveRecord::Migration
  def up
    drop_table :optionings
    drop_table :option_levels
  end

  def down
  end
end
