require 'translatable'

class Option < ActiveRecord::Base
  include Translatable

  has_many(:option_sets, :through => :option_settings)
  has_many(:option_settings)
  has_many(:translations, :class_name => "Translation", :foreign_key => :obj_id, 
    :conditions => "class_name='Option'")
  
  def name(lang = nil)
    translation_for(:name, lang)
  end
end
