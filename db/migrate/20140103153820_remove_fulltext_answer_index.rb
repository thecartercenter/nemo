class RemoveFulltextAnswerIndex < ActiveRecord::Migration
  def up
    remove_index :answers, :name => :fulltext_answers
  end

  def down
  end
end
