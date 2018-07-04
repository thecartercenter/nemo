class DropAnswersQuestionId < ActiveRecord::Migration[4.2]
  def up
    remove_column :answers, :question_id if Answer.column_names.include?('question_id')
    remove_column :answers, :questionable_id if Answer.column_names.include?('questionable_id')
  end

  def down
  end
end
