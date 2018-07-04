class AddIsStandardAndStandardCopyToOptionNodes < ActiveRecord::Migration[4.2]
  def change
    add_column :option_nodes, :is_standard, :boolean, default: false
    add_column :option_nodes, :standard_copy, :boolean, default: false, null: false
  end
end
