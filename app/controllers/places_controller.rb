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
class PlacesController < ApplicationController
  
  def index
    @places = load_objects_with_subindex(Place)
  end
  def map
    @place = Place.permanent.find(params[:id])
    @places = [@place]
    @bounds = @place.bounds
    @title = "Map: #{@place.full_name}"
    @js << "map"
    render(:action => :map_all)
  end
  def map_all
    @title = "Place Map"
    @js << "map"
    @places = Place.permanent.where("places.latitude is not null and places.longitude is not null")
    @bounds = Place.bound(@places)
  end
  def new
    set_add_title
    set_js
    @place = Place.permanent.new
  end
  def edit
    # lookup the place
    @place = Place.find(params[:id])
    # setup the required js
    set_js
  end
  def update
    # lookup the place
    @place = Place.find(params[:id])
    # try to update
    if @place.update_attributes(params[:place])
      flash[:success] = "Place updated successfully."
      redirect_to(:action => :index)
    else
      set_js
      render(:action => :edit)
    end
  end
  def create
    @place = Place.new(params[:place])
    if @place.save
      flash[:success] = "Place added successfully."
      redirect_to(:action => :index)
    else
      set_add_title
      set_js
      render(:action => :new)
    end
  end
  def destroy
    @place = Place.find(params[:id])
    begin
      @place.destroy
      flash[:success] = "Place deleted successfully" 
    rescue 
      flash[:error] = $!.to_s
    end
    redirect_to(:action => :index)
  end
  def lookup
    # get a dummy obj from the class specified in the request
    @dummy = Kernel.const_get(params[:class_name]).new
    # make sure it is a valid PlaceLookupable obj
    raise "Bad class name" unless @dummy.respond_to?(:place_lookup_query)
    # lookup places
    @dummy.place_suggestions = Place.lookup(params[:query])
    # render results partial
    render(:partial => "lookup_results", :locals => {:obj => @dummy, :ajax => true})
  end
  private
    def set_add_title
      @title = "Add Place: Manual"
    end
    def set_js
      @js << 'places'
    end
end
