class AddMultiLevelToOptionSets < ActiveRecord::Migration
  def change
    add_column :option_sets, :multilevel, :boolean, :null => false, :default => false
  end
end
