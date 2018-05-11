class AddTemporaryNewRankDefault < ActiveRecord::Migration
  def up
    change_column_default :answers, :new_rank, 0
  end
end
