class AddNewRankToAnswers < ActiveRecord::Migration[4.2]
  def change
    add_column :answers, :new_rank, :integer
    add_index :answers, :new_rank
  end
end
