class Questioning < ActiveRecord::Base
  belongs_to(:form)
  belongs_to(:question)
  
  def answer_required?
    required? && question.type.name != "select_multiple"
  end
end
