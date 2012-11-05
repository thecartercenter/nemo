require 'seedable'
class QuestionType < ActiveRecord::Base
  include Seedable
  
  has_many(:questions, :inverse_of => :type)
  
  default_scope(order("long_name"))
  
  def self.generate
    seed(:name, :name => "text", :long_name => "Short Text", :odk_name => "string", :odk_tag => "input")
    seed(:name, :name => "long_text", :long_name => "Long Text", :odk_name => "string", :odk_tag => "input")
    seed(:name, :name => "integer", :long_name => "Integer", :odk_name => "int", :odk_tag => "input")
    seed(:name, :name => "decimal", :long_name => "Decimal", :odk_name => "decimal", :odk_tag => "input")
    seed(:name, :name => "location", :long_name => "GPS Location", :odk_name => "geopoint", :odk_tag => "input")
    seed(:name, :name => "address", :long_name => "Address/Landmark", :odk_name => "string", :odk_tag => "input")
    seed(:name, :name => "select_one", :long_name => "Select One", :odk_name => "select1", :odk_tag => "select1")
    seed(:name, :name => "select_multiple", :long_name => "Select Multiple", :odk_name => "select", :odk_tag => "select")
    seed(:name, :name => "datetime", :long_name => "Date+Time", :odk_name => "dateTime", :odk_tag => "input")
    seed(:name, :name => "date", :long_name => "Date", :odk_name => "date", :odk_tag => "input")
    seed(:name, :name => "time", :long_name => "Time", :odk_name => "time", :odk_tag => "input")
  end

  def numeric?
    name == "integer" || name == "decimal"
  end
  def integer?; name == "integer"; end
  
  def printable?; name != "location"; end
  
  def qing_ids
    questions.collect{|q| q.qing_ids}.flatten
  end
  
  def has_timezone?
    name == "datetime"
  end
  
  def temporal?
    %w(datetime date time).include?(name)
  end
end
