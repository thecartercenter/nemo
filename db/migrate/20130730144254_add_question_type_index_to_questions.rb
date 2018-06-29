class AddQuestionTypeIndexToQuestions < ActiveRecord::Migration[4.2]
  def change
    add_index :questions, [:qtype_name]
  end
end
