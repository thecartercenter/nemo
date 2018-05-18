# frozen_string_literal: true

# Temporary change until full migration is done.
class RemoveNewRankNullConstraintTemporarily < ActiveRecord::Migration
  def change
    change_column_null :answers, :new_rank, true
  end
end
