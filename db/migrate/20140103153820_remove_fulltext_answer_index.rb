class RemoveFulltextAnswerIndex < ActiveRecord::Migration[4.2]
  def up
    remove_index :answers, name: :fulltext_answers
  rescue StandardError
    # in case it doesnt exist, don't complain
  end

  def down
  end
end
