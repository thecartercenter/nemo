class RemoveUniqueIndexFromOptionSets < ActiveRecord::Migration
  def up
    remove_index "option_sets", ["mission_id", "name"]
  end

  def down
  end
end
