# ELMO - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# ELMO is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ELMO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ELMO.  If not, see <http://www.gnu.org/licenses/>.
# 
require 'seedable'
class QuestionType < ActiveRecord::Base
  include Seedable
  
  has_many(:questions)
  
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
  
  def self.select_options
    all.collect{|qt| [qt.long_name, qt.id]}
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
