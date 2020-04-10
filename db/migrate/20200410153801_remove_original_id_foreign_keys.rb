# frozen_string_literal: true

class RemoveOriginalIdForeignKeys < ActiveRecord::Migration[5.2]
  def change
    # Removing these because there is not a big downside and the upside is we can
    # still use original_id across systems if we don't have to meet this requirement.
    remove_foreign_key "forms", "forms"
    remove_foreign_key "option_nodes", "option_nodes"
    remove_foreign_key "option_sets", "option_sets"
    remove_foreign_key "questions", "questions"
  end
end
