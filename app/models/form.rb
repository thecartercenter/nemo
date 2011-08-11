class Form < ActiveRecord::Base
  has_many(:questions, :through => :questionings)
  has_many(:questionings, :order => "rank")
  has_many(:responses)
  belongs_to(:type, :class_name => "FormType", :foreign_key => :form_type_id)
  
  def self.per_page
    1000000
  end
  
  def self.published(params)
    sorted(params.merge(:conditions => "forms.is_published = 1"))
  end
  
  def self.sorted(params)
    params.merge!(:order => "form_types.name, forms.name")
    paginate(:all, params)
  end
  
  def self.default_eager
    [:questions, :responses, :type]
  end
  
  def self.find_eager(id)
    find(id, :include => [:type, {:questionings => {:question => 
        [:type, :translations, {:option_set => {:option_settings => {:option => :translations}}}]
    }}])
  end
  
  def self.select_options
    all(:include => :type, :order => "form_types.name, forms.name").collect{|f| [f.full_name, f.id]}
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
