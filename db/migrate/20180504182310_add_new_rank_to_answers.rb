class AddNewRankToAnswers < ActiveRecord::Migration[4.2]
  def up
    add_column :answers, :new_rank, :integer
    add_index :answers, :new_rank
  end

  def down
    remove_column :answers, :new_rank
  end
end
