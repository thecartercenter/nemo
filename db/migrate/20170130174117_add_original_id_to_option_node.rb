class AddOriginalIdToOptionNode < ActiveRecord::Migration[4.2]
  def up
    unless OptionNode.column_names.include?("original_id")
      add_column :option_nodes, :original_id, :integer, index: true
    end
    add_foreign_key "option_nodes", "option_nodes", column: "original_id", name: "option_nodes_standard_id_fk", on_delete: :nullify
  end
end
