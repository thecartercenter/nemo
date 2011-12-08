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
class SettingsController < ApplicationController
  def index
    # load all settings
    @settings = Setting.load_and_create
  end
  
  def update_all
    @settings = Setting.find_and_update_all(params[:settings].values)
    # for each setting, update
    unless @settings.detect{|s| !s.valid?}
      flash[:success] = "Settings updated successfully."
      redirect_to(:action => :index)
    else
      flash[:error] = "Settings have errors. Please see below."
      render(:action => :index)
    end
  end
end
