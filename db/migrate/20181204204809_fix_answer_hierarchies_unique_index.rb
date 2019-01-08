# frozen_string_literal: true

# generations shouldn't be in this index. It is derivative and would never be used in a lookup.
# Furthermore, any given node pair have only one entry in the hierarchies table.
class FixAnswerHierarchiesUniqueIndex < ActiveRecord::Migration[5.1]
  def up
    remove_index(:answer_hierarchies, %i[ancestor_id descendant_id generations])
    add_index(:answer_hierarchies, %i[ancestor_id descendant_id], unique: true)
  end
end
