class CreateAnswersFulltextIndex < ActiveRecord::Migration
  def up
    execute('CREATE FULLTEXT INDEX fulltext_answers ON answers (value)')
  end

  def down
  end
end
