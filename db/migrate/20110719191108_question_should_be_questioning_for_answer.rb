class QuestionShouldBeQuestioningForAnswer < ActiveRecord::Migration[4.2]
  def self.up
    add_column(:answers, :questioning_id, :integer)
    connection.execute("update answers a, responses r, questionings qing  set a.questioning_id=qing.id where a.response_id=r.id and qing.form_id=r.form_id and qing.question_id=a.question_id")
    remove_column(:answers, :question_id)
  end

  def self.down
  end
end
