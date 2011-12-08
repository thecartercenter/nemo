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
class OptionsController < ApplicationController
  def index
    @options = load_objects_with_subindex(Option)
  end
  
  def new
    @option = Option.new
  end
  
  def edit
    @option = Option.find(params[:id])
  end

  def show
    @option = Option.find(params[:id])
  end

  def destroy
    @option = Option.find(params[:id])
    begin flash[:success] = @option.destroy && "Option deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end
  
  def create; crupdate; end
  def update; crupdate; end
  
  private
    def crupdate
      action = params[:action]
      @option = action == "create" ? Option.new : Option.find(params[:id])
      begin
        @option.update_attributes!(params[:option])
        flash[:success] = "Option #{action}d successfully."
        redirect_to(:action => :index)
      rescue ActiveRecord::RecordInvalid
        render(:action => action == "create" ? :new : :edit)
      end
    end
end
