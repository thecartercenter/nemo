class RemoveQuestionCodeSpaces < ActiveRecord::Migration[4.2]
  def up
    # Now obsolete
    # Question.all.each{|q| q.code = q.code.gsub(" ", ""); q.save(:validate => false)}
  end

  def down
  end
end
