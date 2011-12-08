# Elmo - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# Elmo is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Elmo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Elmo.  If not, see <http://www.gnu.org/licenses/>.
# 
class Role < ActiveRecord::Base
  has_many(:users)
  
  def self.sorted
    find(:all, :order => "level")
  end
  def self.select_options
    sorted.collect{|r| [r.name, r.id]}
  end
  def to_s
    name
  end
  def is_observer?; level == 1; end
  def is_program_staff?; level == 4; end
end
