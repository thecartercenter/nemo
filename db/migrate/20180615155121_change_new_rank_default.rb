# frozen_string_literal: true

# This column hasn't been used in production yet so we can remove and replace it
# rather than dealing with migrating data.
class ChangeNewRankDefault < ActiveRecord::Migration
  def up
    remove_column :answers, :new_rank
    add_column :answers, :new_rank, :integer, null: false, default: 0, index: true
  end
end
