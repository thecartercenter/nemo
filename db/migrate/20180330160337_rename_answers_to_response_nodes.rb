class RenameAnswersToResponseNodes < ActiveRecord::Migration
  def change
    rename_table :answer_hierarchies, :response_node_hierarchies
    rename_table :answers, :response_nodes
    rename_column :choices, :answer_id, :response_node_id
    rename_column :media_objects, :answer_id, :response_node_id
  end
end
