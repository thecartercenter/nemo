class AddLevelNamesToOptionSets < ActiveRecord::Migration
  def change
    add_column :option_sets, :level_names, :text
  end
end
