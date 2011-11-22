class QuestionType < ActiveRecord::Base
  has_many(:questions)
  
  def self.select_options
    all(:order => "long_name").collect{|qt| [qt.long_name, qt.id]}
  end
  def numeric?
    name == "integer" || name == "decimal"
  end
  def integer?; name == "integer"; end
end
