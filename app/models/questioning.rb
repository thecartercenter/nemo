class Questioning < ActiveRecord::Base
  belongs_to(:form)
  belongs_to(:question, :autosave => true)
  has_many(:answers)

  def answer_required?
    required? && question.type.name != "select_multiple"
  end
  
  def method_missing(*args)
    # pass appropriate methods on to question
    if is_question_method?(args[0])
      question.send(*args)
    else
      super
    end
  end
  
  def respond_to_missing?(symbol, include_private)
    is_question_method?(symbol) || super
  end
  
  def is_question_method?(symbol)
    symbol.match(/^((name|hint)_([a-z]{3})(=?)|code=?|option_set_id=?|question_type_id=?)(_before_type_cast)?$/)
  end
end
