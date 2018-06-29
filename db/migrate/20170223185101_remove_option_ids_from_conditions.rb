class RemoveOptionIdsFromConditions < ActiveRecord::Migration[4.2]
  def change
    remove_column :conditions, :option_ids, :string
  end
end
