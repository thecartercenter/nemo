class RemoveOptionIdsFromConditions < ActiveRecord::Migration
  def change
    remove_column :conditions, :option_ids, :string
  end
end
