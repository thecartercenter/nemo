# frozen_string_literal: true

class AddDefaultForNewRank < ActiveRecord::Migration
  def up
    change_column :answers, :new_rank, :integer, default: 0, null: false
  end
end
