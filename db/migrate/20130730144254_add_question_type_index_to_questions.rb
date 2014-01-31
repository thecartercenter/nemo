class AddQuestionTypeIndexToQuestions < ActiveRecord::Migration
  def change
    add_index :questions, [:qtype_name]
  end
end
