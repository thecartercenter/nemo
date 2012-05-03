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
class PlaceType < ActiveRecord::Base
  include Seedable
  
  has_many(:places)
  
  default_scope(order("level"))
  scope(:except_point, where("level <= 4"))

  def self.generate
    seed(:level, :name => "Country", :short_name => "country", :level => "1")
    seed(:level, :name => "State/Province", :short_name => "state", :level => "2")
    seed(:level, :name => "Locality", :short_name => "locality", :level => "3")
    seed(:level, :name => "Address/Landmark", :short_name => "address", :level => "4")
    seed(:level, :name => "Point", :short_name => "point", :level => "5")
  end

  def self.select_options
    all.reverse.collect{|pt| [pt.name, pt.id]}
  end
  def self.country
    find_by_level(1)
  end
  def self.address
    find_by_level(4)
  end
  def self.point
    find_by_level(5)
  end
  def self.shortcut_codes
    all.collect{|pt| pt.short_name}
  end
  def is_address?; level == 4; end
end
