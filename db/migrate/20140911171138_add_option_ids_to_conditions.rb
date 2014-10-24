class AddOptionIdsToConditions < ActiveRecord::Migration
  def change
    add_column :conditions, :option_ids, :string
    execute("UPDATE conditions SET option_ids = IF(option_id IS NULL, NULL, CONCAT('[', option_id, ']'))")
  end
end
