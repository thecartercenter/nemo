# frozen_string_literal: true

class AddDefaultForNewRank < ActiveRecord::Migration[4.2]
  def up
    change_column :answers, :new_rank, :integer, default: 0, null: false
  end
end
