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
class FormTypesController < ApplicationController
  def index
    @form_types = load_objects_with_subindex(FormType)
  end
  
  def new
    @form_type = FormType.new
    render(:form)
  end
  
  def edit
    @form_type = FormType.find(params[:id])
    render(:form)
  end

  def show
    @form_type = FormType.find(params[:id])
    render(:form)
  end

  def destroy
    @form_type = FormType.find(params[:id])
    begin 
      flash[:success] = @form_type.destroy && "Form Type deleted successfully." 
    rescue
      flash[:error] = $!.to_s
    end
    redirect_to(:action => :index)
  end
  
  def create; crupdate; end
  def update; crupdate; end

  private
    def crupdate
      action = params[:action]
      @form_type = action == "create" ? FormType.new : FormType.find(params[:id])
      begin
        @form_type.update_attributes!(params[:form_type])
        flash[:success] = "Form Type #{action}d successfully."
        redirect_to(:action => :index)
      rescue ActiveRecord::RecordInvalid
        render(:form)
      end
    end
end
