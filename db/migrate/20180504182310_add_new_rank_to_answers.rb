class AddNewRankToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :new_rank, :integer
    execute("UPDATE answers SET new_rank = 0")
    change_column_null :answers, :new_rank, false
    add_index :answers, :new_rank
  end
end
