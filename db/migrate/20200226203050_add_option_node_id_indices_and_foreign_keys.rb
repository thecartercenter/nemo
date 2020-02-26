# frozen_string_literal: true

class AddOptionNodeIdIndicesAndForeignKeys < ActiveRecord::Migration[5.2]
  def change
    add_index :answers, :option_node_id
    add_index :choices, :option_node_id
    add_foreign_key :answers, :option_nodes
    add_foreign_key :choices, :option_nodes
  end
end
