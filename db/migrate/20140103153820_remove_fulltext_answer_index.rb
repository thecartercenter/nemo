class RemoveFulltextAnswerIndex < ActiveRecord::Migration
  def up
    begin
      remove_index :answers, :name => :fulltext_answers
    rescue
      # in case it doesnt exist, don't complain
    end
  end

  def down
  end
end
