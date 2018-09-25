# frozen_string_literal: true

class RenameRankToOldRankInAnswers < ActiveRecord::Migration[5.1]
  def change
    rename_column(:answers, :rank, :old_rank)
  end
end
