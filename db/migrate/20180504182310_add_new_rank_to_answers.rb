class AddNewRankToAnswers < ActiveRecord::Migration
  def up
    add_column :answers, :new_rank, :integer
    execute("UPDATE answers SET new_rank = 0")
    change_column_null :answers, :new_rank, false
    add_index :answers, :new_rank
  end

  def down
    remove_column :answers, :new_rank
  end
end
