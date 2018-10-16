# frozen_string_literal: true

class TightenChoiceTableConstraints < ActiveRecord::Migration[5.1]
  def up
    # These can't possibly have any use.
    execute("DELETE FROM choices WHERE answer_id IS NULL OR option_id IS NULL")
    change_column_null(:choices, :answer_id, false)
    change_column_null(:choices, :option_id, false)
  end
end
