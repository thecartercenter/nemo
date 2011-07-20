class Answer < ActiveRecord::Base
  belongs_to(:questioning)
  belongs_to(:option)
  belongs_to(:response)
  
  validates(:value, :numericality => true, :if => Proc.new{|a| a.questioning && a.questioning.question.type.name == "numeric"})
  
  def copy_data_from(a)
    logger.debug("copied #{a.value} and #{a.option_id}")
    self.value = a.value
    self.option_id = a.option_id
  end
  
  def question
    questioning ? questioning.question : nil
  end
end
