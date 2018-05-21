class AddNewRankToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :new_rank, :integer
    add_index :answers, :new_rank
  end
end
