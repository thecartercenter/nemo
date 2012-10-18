class Report::ByAnswerGrouping < Report::Grouping
  belongs_to(:question)
  
  def apply(rel)
    wrapper.apply(rel, :group => true)
  end
  
  def wrapper
    @wrapper ||= Report::QuestionWrapper.new(question)
  end
  
  def sql_col_name
    wrapper.sql_col_name
  end
  
  def form_choice
    "by_answer_#{question_id}"
  end
  
  def assoc_id=(id)
    self.question_id = id
  end
  
  def to_s
    question.code
  end
end