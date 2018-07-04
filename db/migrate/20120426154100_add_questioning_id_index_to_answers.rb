class AddQuestioningIdIndexToAnswers < ActiveRecord::Migration[4.2]
  def change
    add_index(:answers, [:questioning_id])
  end
end
