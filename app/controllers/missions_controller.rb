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
class MissionsController < ApplicationController
  def index
    @missions = Mission.all
  end
  
  def new
    @mission = Mission.new
    render(:form)
  end
  
  def edit
    @mission = Mission.find(params[:id])
    render(:form)
  end

  def destroy
    begin
      (@mission = Mission.find(params[:id])).destroy
      flash[:success] = "Mission deleted successfully." 
    rescue
      flash[:error] = $!.to_s
    end
    redirect_to(:action => :index)
  end
  
  def create
    begin
      (@mission = Mission.new(params[:mission])).save!
      flash[:success] = "Mission created successfully."
      redirect_to(:action => :index)
    rescue ActiveRecord::RecordInvalid
      render(:form)
    end
  end
  
  def update
    begin
      (@mission = Mission.find(params[:id])).update_attributes!(params[:mission])
      flash[:success] = "Mission updated successfully."
      redirect_to(:action => :index)
    rescue ActiveRecord::RecordInvalid
      render(:form)
    end
  end
end
