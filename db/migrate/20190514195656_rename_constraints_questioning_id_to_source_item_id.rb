# frozen_string_literal: true

class RenameConstraintsQuestioningIdToSourceItemId < ActiveRecord::Migration[5.2]
  def change
    rename_column :constraints, :questioning_id, :source_item_id
  end
end
