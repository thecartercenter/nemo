class Questioning < ActiveRecord::Base
  belongs_to(:form)
  belongs_to(:question, :autosave => true)
  has_many(:answers)
  
  before_create(:set_rank)
  before_destroy(:check_assoc)

  def self.new_with_question(params = {})
    qing = new(params.merge(:question => Question.new))
  end

  def answer_required?
    required? && question.type.name != "select_multiple"
  end
  
  def published?
    form.is_published?
  end
  
  # returns any forms other than this one on which this questionings question appears
  def other_forms
    question.forms.reject{|f| f == form}
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
  
  def update_rank(rank)
    self.rank = rank
    save
  end
  
  private
    def set_rank
      self.rank = form.max_rank + 1 if rank.nil?
    end
    
    def check_assoc
      unless answers.empty?
        raise("You can't remove question '#{question.code}' because it has one or more answers for this form.")
      end
    end
end
