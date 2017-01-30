class AddOriginalIdToOptionNode < ActiveRecord::Migration
  def up
    add_column :option_nodes, :original_id, :integer, index: true
    add_foreign_key "option_nodes", "option_nodes", column: "original_id", name: "option_nodes_standard_id_fk", on_delete: :nullify
  end
end
