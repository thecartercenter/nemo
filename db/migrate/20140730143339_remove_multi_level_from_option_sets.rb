class RemoveMultiLevelFromOptionSets < ActiveRecord::Migration
  def up
    remove_column :option_sets, :multilevel
  end

  def down
    add_column :option_sets, :multilevel, :boolean
  end
end
