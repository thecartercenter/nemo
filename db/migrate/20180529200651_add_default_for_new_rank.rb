# frozen_string_literal: true

class AddDefaultForNewRank < ActiveRecord::Migration
  def change
    change_column :answers, :new_rank, :integer, default: 1, null: false
  end
end
