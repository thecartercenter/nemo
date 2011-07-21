class Form < ActiveRecord::Base
  has_many(:questions, :through => :questionings)
  has_many(:questionings, :order => "rank")
  belongs_to(:type, :class_name => "FormType", :foreign_key => :form_type_id)
  
  def self.published
    find(:all, :conditions => "is_published = 1", :order => "name")
  end
  
  def self.find_eager(id)
    find(id, :include => [:type, {:questionings => {:question => 
        [:type, :translations, {:option_set => {:option_settings => {:option => :translations}}}]
     }}])
  end
  
  def temp_response_id
    "#{name}_#{ActiveSupport::SecureRandom.random_number(899999999) + 100000000}"
  end
  
  def version
    "1.0" # this isn't implemented yet
  end
  
  def full_name
    "#{type.name}: #{name}"
  end
  
  def option_sets
    questions.collect{|q| q.option_set}.compact.uniq
  end
  
  def visible_questionings
    questionings.reject{|q| q.hidden}
  end
end
