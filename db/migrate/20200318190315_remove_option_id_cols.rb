# frozen_string_literal: true

class RemoveOptionIdCols < ActiveRecord::Migration[5.2]
  def change
    remove_column(:answers, :option_id, :uuid)
    remove_column(:choices, :option_id, :uuid)
  end
end
