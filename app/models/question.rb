class Question < ActiveRecord::Base
  belongs_to(:type, :class_name => "QuestionType", :foreign_key => :question_type_id)
  def name(lang = nil)
    Translation.lookup(self.class.name, id, 'name', lang)
  end
  def hint(lang = nil)
    Translation.lookup(self.class.name, id, 'hint', lang)
  end
end
