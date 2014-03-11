class AddMultiLevelToOptionSets < ActiveRecord::Migration
  def change
    add_column :option_sets, :multi_level, :boolean, :null => false, :default => false
  end
end
