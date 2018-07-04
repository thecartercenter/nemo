class AddStandardIdAndIsStandardToOptionNodes < ActiveRecord::Migration[4.2]
  def change
    add_column :option_nodes, :standard_id, :integer
    add_column :option_nodes, :is_standard, :boolean, :null => false, :default => false
    add_foreign_key :option_nodes, :option_nodes, :column => :standard_id
  end
end
