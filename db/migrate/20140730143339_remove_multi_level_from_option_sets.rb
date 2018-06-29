class RemoveMultiLevelFromOptionSets < ActiveRecord::Migration[4.2]
  def up
    remove_column :option_sets, :multilevel
  end

  def down
    add_column :option_sets, :multilevel, :boolean
  end
end
