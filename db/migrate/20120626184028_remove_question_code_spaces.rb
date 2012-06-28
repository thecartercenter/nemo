class RemoveQuestionCodeSpaces < ActiveRecord::Migration
  def up
    Question.all.each{|q| q.code = q.code.gsub(" ", ""); q.save(:validate => false)}
  end

  def down
  end
end
