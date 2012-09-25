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
require 'language_list'
class Setting < ActiveRecord::Base
  include MissionBased
  include LanguageList

  KEYS = %w(timezone languages)
  DEFAULTS = {:timezone => "UTC", :languages => "eng"}

  scope(:by_mission, lambda{|m| where(:mission_id => m ? m.id : nil)})
  scope(:default, where(DEFAULTS))
  
  before_validation(:cleanup_languages)
  before_validation(:ensure_english)
  validate(:lang_codes_are_valid)
  
  
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
    setting = by_mission(mission).first || by_mission(mission).default.create
  end
  
  # copies all settings for the given mission to configatron
  def self.copy_to_config(mission)
    return if !table_exists?
    
    # get the setting or default
    find_or_create(mission).copy_to_config
  end
  
  def copy_to_config
    # build hash
    hsh = Hash[*KEYS.collect{|k| [k.to_sym, send(k)]}.flatten]
    hsh[:languages] = lang_codes
    
    # copy to configatron
    configatron.configure_from_hash(hsh)
  end
  
  # converts a comma-delimited string of languages to an array of symbols
  def lang_codes
    (languages || "").split(",").collect{|c| c.to_sym}
  end
  
  # reverse of self.lang_codes
  def lang_codes=(codes)
    self.languages = codes.join(",")
  end
  
  private
    def ensure_english
      # make sure english exists and is at the front
      self.lang_codes = (lang_codes - [:eng]).insert(0, :eng)
      return true
    end
    
    def cleanup_languages
      self.lang_codes = lang_codes.collect{|c| c.to_s.downcase.gsub(/[^a-z]/, "").to_sym}
      return true
    end
    
    def lang_codes_are_valid
      lang_codes.each do |lc|
        errors.add(:languages, "code #{lc} is invalid") unless LANGS.keys.include?(lc)
      end
    end
end
