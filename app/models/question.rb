class Question < ActiveRecord::Base
  belongs_to(:type, :class_name => "QuestionType", :foreign_key => :question_type_id)
  belongs_to(:option_set, :include => :options)
  has_many(:answers)
  
  def name(lang = nil)
    Translation.lookup(self.class.name, id, 'name', lang)
  end
  def hint(lang = nil)
    Translation.lookup(self.class.name, id, 'hint', lang)
  end
  def options
    option_set ? option_set.options : nil
  end
  def is_select?
    type.name.match(/^select/)
  end
  def new_answers_from_str(str)
    # if this is a select multiple, split the string on " " and call new_answer for each
    if !str.blank? && type.name == "select_multiple"
      str.split(" ").collect{|v| new_answer(v)}
    else
      [new_answer(str)]
    end
  end
  def new_answer(value)
    # get option or value
    params = {}
    if is_select?
      params[:option_id] = begin 
        options.find(value.to_i).id 
      rescue 
        logger.error("Invalid option for question '#{code}'.")
        nil 
      end
    else
      params[:value] = value
    end
    
    # if question is numeric but value is not numeric, just set to nil
    if type.name == "numeric" && !params[:value].match(/^[-+]?[0-9]*\.?[0-9]+$/)
      logger.error("Invalid value given for numeric question '#{code}'.")
      params[:value] = nil
    end
    
    # initialize and return
    answers.new(params)
  end
  def is_location?
    type.name == "location"
  end
  def is_address?
    type.name == "address"
  end
  def is_start_timestamp?
    type.name == "start_timestamp"
  end
end
