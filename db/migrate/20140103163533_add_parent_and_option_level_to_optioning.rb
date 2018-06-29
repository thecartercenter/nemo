class AddParentAndOptionLevelToOptioning < ActiveRecord::Migration[4.2]
  def change
    add_column :optionings, :parent_id, :integer
    add_column :optionings, :option_level_id, :integer
    add_foreign_key :optionings, :optionings, :column => :parent_id
    add_foreign_key :optionings, :option_levels
  end
end
