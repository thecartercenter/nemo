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
class SearchesController < ApplicationController
  
  def create
    # find/create the search object from the given params
    search = Search.find_or_create(params[:search])
    # save it in the appropriate subindex object
    subindex = Subindex.find_or_create(session, current_user, search.class_name)
    subindex.search = search
    # redirect to the appropriate index page
    return_to_index(search)
  end
  # this is a GET method that just copies parameters and calls create
  def start
    params[:search] = {}
    [:query, :class_name].each{|k| params[:search][k] = params.delete(k)}
    create
  end
  def update
    create
  end
  private
    # redirects to the appropriate index page for the given search
    def return_to_index(search)
      redirect_to(:controller => search.class_name.pluralize.underscore, :action => :index)
    end
end
