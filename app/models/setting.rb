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
class Setting < ActiveRecord::Base
  belongs_to(:settable)
  
  def self.table_exists?
    ActiveRecord::Base.connection.tables.include?("settings")
  end
  
  # loads or creates one setting for each settable in the database
  def self.load_and_create
    return [] unless table_exists?
    Settable.all.collect{|sb| sb.setting_or_default}
  end
  
  def self.find_and_update_all(params)
    return [] unless table_exists?
    updated = params.collect{|p| s = find(p[:id]); s.update_attributes(:value => p[:value]); s}
    copy_all_to_config
    updated
  end
  
  def self.copy_all_to_config
    return unless table_exists?
    configatron.configure_from_hash(Hash[*load_and_create.collect{|s| [s.settable.key, s.value]}.flatten])
  end
end
