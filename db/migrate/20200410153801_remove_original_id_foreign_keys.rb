# frozen_string_literal: true

class RemoveOriginalIdForeignKeys < ActiveRecord::Migration[5.2]
  def change
    # The only thing this foreign key is used for is for tracking which original object
    # copies point to so that they are not duplicated during subsequent copies.
    # (e.g. so the same question is not copied twice when two different forms that use
    # it are imported to a mission).
    # But if there is a constraint on the foreign key then it means we can't use it across
    # different servers, which could end up being useful.
    # So let's remove the constraint.
    remove_foreign_key "forms", "forms"
    remove_foreign_key "option_nodes", "option_nodes"
    remove_foreign_key "option_sets", "option_sets"
    remove_foreign_key "questions", "questions"
  end
end
