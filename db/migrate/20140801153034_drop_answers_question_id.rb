class DropAnswersQuestionId < ActiveRecord::Migration
  def up
    remove_column :answers, :question_id
  end

  def down
  end
end
