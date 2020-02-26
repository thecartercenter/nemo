# frozen_string_literal: true

class AddOptionNodeIdToAnswersAndChoices < ActiveRecord::Migration[5.2]
  def change
    # Skipping indices and foreign keys ATM for performance reasons.
    add_reference :answers, :option_node, type: :uuid, index: false, foreign_key: false
    add_reference :choices, :option_node, type: :uuid, index: false, foreign_key: false
  end
end
