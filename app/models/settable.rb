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
  
  has_one(:setting)
  
  def self.generate
    seed(:key, :key => "timezone", :name => "Time Zone", :description => "The time zone in which times are displayed throughout the site.", :kind => "timezone", :default => "UTC")
  end
  
  def setting_or_default
    setting || Setting.create(:settable_id => id, :value => default)
  end
end
