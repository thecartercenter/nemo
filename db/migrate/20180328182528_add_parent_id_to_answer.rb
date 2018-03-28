# frozen_string_literal: true

# Add parent_id to answers for closure_tree
class AddParentIdToAnswer < ActiveRecord::Migration
  def change
    add_column :answers, :parent_id, :uuid
  end
end
