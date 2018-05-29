# frozen_string_literal: true

class AddDefaultForNewRank < ActiveRecord::Migration
  def change
    #execute("UPDATE answers SET new_rank = 1 WHERE new_rank IS NULL OR new_rank = 0")
    change_column :answers, :new_rank, :integer, default: 1, null: false
  end
end
