# frozen_string_literal: true

class AddAnswerHierarchyForeignKeys < ActiveRecord::Migration[5.2]
  def up
    execute("DELETE FROM answer_hierarchies WHERE NOT EXISTS
      (SELECT id FROM answers WHERE id = answer_hierarchies.ancestor_id)")
    execute("DELETE FROM answer_hierarchies WHERE NOT EXISTS
      (SELECT id FROM answers WHERE id = answer_hierarchies.descendant_id)")
    add_foreign_key :answer_hierarchies, :answers, column: :ancestor_id
    add_foreign_key :answer_hierarchies, :answers, column: :descendant_id
  end
end
