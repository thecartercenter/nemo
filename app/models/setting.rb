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

  belongs_to(:settable)
  
  def self.table_exists?
    ActiveRecord::Base.connection.tables.include?("settings")
  end
  
  # loads or creates one setting (for the given mission) for each settable in the database
  # if mission is nil, only loads/creates mission independent settings
  def self.load_and_create(mission)
    return [] unless table_exists?
    
    # for each settable, get the existing setting, or the default (which is defined in settable)
    Settable.all.collect{|sb| sb.setting_or_default(mission)}.compact
  end
  
  # called by the controller; updates settings with the given values
  # accepts an array of hashes of the format {:id => id, :value => value}
  def self.find_and_update_all(params)
    return [] unless table_exists?
    
    # save new values to database and get updated settings objects
    updated = params.collect{|p| s = find(p[:id]); s.update_attributes(:value => p[:value]); s}
    
    # copy the update values to the config
    copy_all_to_config
    
    # return the updated settings objects
    updated
  end
  
  # copies all settings for the given mission to configatron
  def self.copy_all_to_config(mission = nil)
    return unless table_exists?
    configatron.configure_from_hash(Hash[*load_and_create(mission).collect{|s| [s.settable.key, s.value]}.flatten])
  end
end
