class Question < ActiveRecord::Base
  belongs_to(:type, :class_name => "QuestionType", :foreign_key => :question_type_id)
  belongs_to(:option_set)
  
  def name(lang = nil)
    Translation.lookup(self.class.name, id, 'name', lang)
  end
  def hint(lang = nil)
    Translation.lookup(self.class.name, id, 'hint', lang)
  end
  def options
    option_set ? option_set.options : nil
  end
end
