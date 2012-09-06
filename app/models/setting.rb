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
require 'mission_based'
class Setting < ActiveRecord::Base
  include MissionBased

  scope(:by_mission, lambda{|m| where(:mission_id => m ? m.id : nil)})
  scope(:default, where(:timezone => "UTC"))
  
  def self.table_exists?
    ActiveRecord::Base.connection.tables.include?("settings")
  end
  
  # gets called each time the current_mission is set by the application controller
  # checks if the settings have been copied to configatron since the *app* (not the request) was started
  def self.mission_was_set(mission)
    unless configatron.settings_copied?
      configatron.settings_copied = true
      copy_to_config(mission)
    end
  end
  
  # loads or creates a setting for the given mission
  def self.find_or_create(mission)
    return nil unless table_exists?
    by_mission(mission).first || by_mission(mission).default.create
  end
  
  # copies all settings for the given mission to configatron
  def self.copy_to_config(mission)
    return if !table_exists?
    
    # get the setting or default
    find_or_create(mission).copy_to_config
  end
  
  def copy_to_config
    # build hash
    hsh = Hash[*%w(timezone).collect{|k| [k, send(k)]}.flatten]
    
    # copy to configatron
    configatron.configure_from_hash(hsh)
  end
end
