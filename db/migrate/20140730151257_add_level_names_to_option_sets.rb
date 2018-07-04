class AddLevelNamesToOptionSets < ActiveRecord::Migration[4.2]
  def change
    add_column :option_sets, :level_names, :text
  end
end
