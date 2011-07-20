class Question < ActiveRecord::Base
  belongs_to(:type, :class_name => "QuestionType", :foreign_key => :question_type_id)
  belongs_to(:option_set, :include => :options)
  
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
  def select_options
    (opt = options) ? opt.collect{|o| [o.name, o.id]} : []
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
