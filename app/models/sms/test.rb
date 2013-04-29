# a test request to the sms decoder
class Sms::Test
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  attr_accessor :from, :body
  
  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end
  
  def persisted?
    false
  end
  
  def self.human_attribute_name(a)
    a.to_s.capitalize
  end
  
end