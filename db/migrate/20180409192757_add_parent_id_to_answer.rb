# frozen_string_literal: true

# Add Parent Id to Answer
class AddParentIdToAnswer < ActiveRecord::Migration[4.2]
  def change
    add_column :answers, :parent_id, :uuid
  end
end
