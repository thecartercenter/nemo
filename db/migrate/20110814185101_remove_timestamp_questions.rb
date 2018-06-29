class RemoveTimestampQuestions < ActiveRecord::Migration[4.2]
  def self.up
    # Now obsolete
    # if @qt = QuestionType.where(:name => "start_timestamp").first
    #   @qs = Question.find_all_by_question_type_id(@qt.id)
    #   @qs.each{|q| q.answers.each{|a| a.destroy}; q.questionings.each{|qing| qing.destroy}; Question.find(q.id).destroy}
    # end
  end

  def self.down
  end
end
