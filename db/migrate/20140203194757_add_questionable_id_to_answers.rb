class AddQuestionableIdToAnswers < ActiveRecord::Migration[4.2]
  def change
    add_column :answers, :questionable_id, :integer, :null => false

    # update all existing answers to just use their related question's id
    execute('UPDATE answers a, questionings qing SET a.questionable_id = qing.question_id WHERE a.questioning_id = qing.id')

    add_foreign_key :answers, :questionables
  end
end
