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
class Role < ActiveRecord::Base
  include Seedable
  
  has_many(:users)
  
  default_scope(order("level DESC"))

  def self.generate
    seed(:level, :name => "Coordinator", :level => "3")
    seed(:level, :name => "Staffer", :level => "2")
    seed(:level, :name => "Observer", :level => "1")
  end
  
  def self.highest
    unscoped.order("level DESC").first
  end

  def self.lowest
    unscoped.order("level").first
  end
        
  def to_s
    name
  end
  def observer?; level == 1; end
  def coordinator?; level == 3; end
end
