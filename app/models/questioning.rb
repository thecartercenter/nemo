class Questioning < ActiveRecord::Base
  belongs_to(:form)
  belongs_to(:question)
  has_many(:answers)
  
  def new_answers_from_str(str)
    # if this is a select multiple, split the string on " " and call new_answer for each
    if !str.blank? && question.type.name == "select_multiple"
      str.split(" ").collect{|v| new_answer(v)}
    else
      [new_answer(str)]
    end
  end
  def new_answer(value)
    # get option or value
    params = {}
    if question.is_select?
      params[:option_id] = begin 
        question.options.find(value.to_i).id 
      rescue 
        logger.error("Invalid option for question '#{code}'.")
        nil 
      end
    else
      params[:value] = value
    end
    
    # if question is numeric but value is not numeric, just set to nil
    if question.type.name == "numeric" && !params[:value].match(/^[-+]?[0-9]*\.?[0-9]+$/)
      logger.error("Invalid value given for numeric question '#{code}'.")
      params[:value] = nil
    end
    
    # initialize and return
    answers.new(params)
  end
  def answer_required?
    required? && question.type.name != "select_multiple"
  end
end
