class Form < ActiveRecord::Base
  has_many(:questions, :through => :questionings)
  has_many(:questionings)
  
  def self.published
    find(:all, :conditions => "is_published = 1", :order => "name")
  end
  
  def temp_response_id
    "#{name}_#{ActiveSupport::SecureRandom.random_number(899999999) + 100000000}"
  end
end
