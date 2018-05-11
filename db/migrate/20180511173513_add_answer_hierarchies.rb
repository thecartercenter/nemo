# frozen_string_literal: true

# Iterates over the answers table and inserts the appropriate entries into the answer_hierarchies table.
class AddAnswerHierarchies < ActiveRecord::Migration
  def up
    remove_index "answer_hierarchies", name: "answer_anc_desc_idx"
    remove_index "answer_hierarchies", name: "answer_desc_idx"

    execute("DELETE FROM answer_hierarchies")
    add_for([])

    add_index "answer_hierarchies", %w[ancestor_id descendant_id generations],
      name: "answer_anc_desc_idx", unique: true, using: :btree
    add_index "answer_hierarchies", ["descendant_id"], name: "answer_desc_idx", using: :btree
  end

  private

  def add_for(ancestor_ids)
    parent_where_expr = ancestor_ids.empty? ? "IS NULL" : "= '#{ancestor_ids.last}'"
    (ancestor_ids + [:self]).reverse.each_with_index do |aid, i|
      aid_expr = aid == :self ? "id" : "'#{aid}'"
      execute("INSERT INTO answer_hierarchies(ancestor_id, descendant_id, generations)
        SELECT #{aid_expr}, id, #{i} FROM answers WHERE parent_id #{parent_where_expr}")
    end
    execute("SELECT id FROM answers WHERE parent_id #{parent_where_expr}").each do |row|
      add_for(ancestor_ids + [row["id"]])
    end
  end
end
