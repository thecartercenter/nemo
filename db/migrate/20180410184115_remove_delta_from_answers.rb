# frozen_string_literal: true

# Delta column was used in thinking sphinx, no longer needed
class RemoveDeltaFromAnswers < ActiveRecord::Migration[4.2]
  def change
    remove_column :answers, :delta, :boolean, default: true, null: false
  end
end
