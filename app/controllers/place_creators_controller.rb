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
class PlaceCreatorsController < ApplicationController
  def new
    @place_creator = PlaceCreator.new
    set_title_and_js
  end
  def create
    # at this point all we have to do is just mark the chosen place non-temporary
    @place = Place.find(params[:place_creator][:place_id])
    @place.temporary = false
    begin 
      @place.save!
      flash[:success] = "Place added successfully."
      redirect_to(:action => :new)
    rescue
      flash[:error] = "Problem adding place (#{$!.to_s})."
      set_title_and_js
      render(:action => :new)
    end
  end
  private
    def set_title_and_js
      @title = "Add Place: Using Google"
      @js << "places"
    end
end
