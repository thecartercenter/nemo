require 'translatable'

class Question < ActiveRecord::Base
  include Translatable
  
  belongs_to(:type, :class_name => "QuestionType", :foreign_key => :question_type_id)
  belongs_to(:option_set, :include => :options)
  has_many(:translations, :class_name => "Translation", :foreign_key => :obj_id, 
    :conditions => "class_name='Question'")
  
  def name(lang = nil)
    translation_for(:name, lang)
  end
  def hint(lang = nil)
    translation_for(:hint, lang)
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
