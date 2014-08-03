class RemoveMultiLevelFromOptionSets < ActiveRecord::Migration
  def up
    remove_column :option_sets, :multi_level
  end

  def down
    add_column :option_sets, :multi_level, :boolean
  end
end
