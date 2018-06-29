# frozen_string_literal: true

# Create Answers Hierarchy table, which holds the closure tree-supported hierarchy of ResponseNodes
class CreateAnswerHierarchies < ActiveRecord::Migration[4.2]
  def change
    create_table :answer_hierarchies, id: false do |t|
      t.uuid :ancestor_id, null: false
      t.uuid :descendant_id, null: false
      t.integer :generations, null: false
    end

    add_index :answer_hierarchies, %i[ancestor_id descendant_id generations],
      unique: true,
      name: "answer_anc_desc_idx"

    add_index :answer_hierarchies, [:descendant_id],
      name: "answer_desc_idx"
  end
end
