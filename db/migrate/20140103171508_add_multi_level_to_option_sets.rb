class AddMultiLevelToOptionSets < ActiveRecord::Migration[4.2]
  def change
    add_column :option_sets, :multilevel, :boolean, :null => false, :default => false
  end
end
