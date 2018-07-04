class RemoveQuestionTypes < ActiveRecord::Migration[4.2]
  def up
    # add a qtype_name column to the questions table
    add_column :questions, :qtype_name, :string

    # update all questions to store the question type name directly
    execute("UPDATE questions q INNER JOIN question_types qt ON q.question_type_id=qt.id SET q.qtype_name = qt.name")

    # also update all old address questions to just be text questions (the address question is now obsolete)
    execute("UPDATE questions SET qtype_name = 'text' WHERE qtype_name = 'address'")

    # finally drop the old question_type_id foreign key and index
    remove_column :questions, :question_type_id
  end

  def down
  end
end
