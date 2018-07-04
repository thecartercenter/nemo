# frozen_string_literal: true

# For now. May turn into a composite index later.
class AddParentIdIndexToAnswers < ActiveRecord::Migration[4.2]
  def change
    add_index :answers, :parent_id
  end
end
