class AddRankToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :rank, :integer
  end
end
