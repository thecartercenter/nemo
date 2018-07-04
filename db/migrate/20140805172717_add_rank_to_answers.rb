class AddRankToAnswers < ActiveRecord::Migration[4.2]
  def change
    add_column :answers, :rank, :integer
  end
end
