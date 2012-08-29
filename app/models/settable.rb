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
class Settable < ActiveRecord::Base
  include Seedable
  
  has_many(:settings)
  
  def self.generate
    seed(:key, :key => "timezone", :name => "Time Zone", :description => "The time zone in which times are displayed throughout the site.", :kind => "timezone", :default => "UTC")
  end
  
  # gets the current setting value for the given mission
  # if no mission is provided and the current settable is mission specific, return nil
  def setting_or_default(mission = nil)
    # must have a mission unless the setting is mission_independent
    return nil unless mission_independent? || mission
    
    if mission_independent?
      # return the first setting (there should only be one) or create one
      settings.first || settings.create(:value => default)
    else
      # return the mission specific setting or create one
      settings.for_mission(mission).first || settings.for_mission(mission).create(:value => default)
    end
  end
  
  # not implemented yet
  def mission_independent?
    false
  end
end
