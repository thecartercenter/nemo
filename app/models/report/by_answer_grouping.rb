class Report::ByAnswerGrouping < Report::Grouping
  belongs_to(:question)
  
  def self.select_options
    Question.includes(:type).where(:"question_types.name" => "select_one").all.collect{|q| [human_name(q), "by_answer_#{q.id}"]}
  end
  
  def self.select_group_name; "Questions"; end
  
  def self.human_name(question)
    "#{question.code}"
  end
  
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
    self.class.human_name(question)
  end
end