# frozen_string_literal: true

class RenameInstNumToOldInstNumOnAnswers < ActiveRecord::Migration[5.1]
  def change
    rename_column(:answers, :inst_num, :old_inst_num)
  end
end
