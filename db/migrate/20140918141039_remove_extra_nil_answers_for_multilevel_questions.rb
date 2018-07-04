class RemoveExtraNilAnswersForMultilevelQuestions < ActiveRecord::Migration[4.2]
  def up
    # Remove all nil select_one answers with > 1 rank. These never should have been created.
    execute("delete a from answers a inner join questionings qing on a.questioning_id = qing.id inner join questions q on qing.question_id = q.id where qtype_name = 'select_one' and a.rank > 1 and option_id is null")
  end

  def down
  end
end
