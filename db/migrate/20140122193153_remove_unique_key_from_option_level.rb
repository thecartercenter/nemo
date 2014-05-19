class RemoveUniqueKeyFromOptionLevel < ActiveRecord::Migration
  def up
    # removing this because is causes trouble when trying to reorder
    remove_index :option_levels, :mission_id_and_option_set_id_and_rank
  end

  def down
  end
end
