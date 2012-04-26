class AddQuestioningIdIndexToAnswers < ActiveRecord::Migration
  def change
    add_index(:answers, [:questioning_id])
  end
end
