class AddSmsQuestionNoColumnToQuestions < ActiveRecord::Migration
  def change
    # TOM shouldn't this be in questionings? doesn't it depend on the order of the question on the form? Questions are form independent.
    add_column :questions, :sms_question_no, :integer
  end
end
