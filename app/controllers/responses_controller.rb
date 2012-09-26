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
class ResponsesController < ApplicationController
  def create
    # if this is a submission from ODK collect
    if request.format == Mime::XML
      if %w(HEAD GET).include?(request.method)
        # just render the 'no content' status since that's what odk wants!
        render(:nothing => true, :status => 204)
      elsif upfile = params[:xml_submission_file]
        begin
          contents = upfile.read
          Response.create_from_xml(contents, current_user, current_mission)
          render(:nothing => true, :status => 201)
        rescue ArgumentError
          render(:nothing => true, :status => 404)
        end
      end
    else
      crupdate
    end
  end
  
  def index
    respond_to do |format|
      format.html do
        params[:page] ||= 1
        @responses = apply_filters(Response).all
        @pubd_forms = restrict(Form).published.with_form_type
        render(:partial => "table_only", :locals => {:responses => @responses}) if ajax_request?
      end
      format.csv do
        require 'fastercsv'
        
        # get the response, for export, but not paginated
        @responses = Response.for_export(apply_filters(Response, :pagination => false))

        # render the csv
        render_csv("responses-#{Time.zone.now.to_s(:filename_datetime)}")
      end
    end
  end
  
  def new
    form = Form.with_questions.find(params[:form_id])
    flash[:error] = "You must choose a form to edit." and return redirect_to(:action => :index) unless form
    @response = Response.for_mission(current_mission).new(:form => form)
    render_form
  end
  
  def edit
    @response = Response.find_eager(params[:id])
    render_form
  end
  
  def show
    @response = Response.find_eager(params[:id])
    render_form
  end
  
  def update
    crupdate
  end
  
  def destroy
    @response = Response.find(params[:id])
    begin flash[:success] = @response.destroy && "Response deleted successfully." rescue flash[:error] = $!.to_s end
    redirect_to(:action => :index)
  end
  
  private
    def crupdate
      action = params[:action]
      # source is web, 
      params[:response][:source] = "web" if action == "create"
      params[:response][:modifier] = "web"

      # check for "update and mark as reviewed"
      params[:response][:reviewed] = true if params[:commit_and_mark_reviewed]
      
      # find or create the response
      @response = action == "create" ? Response.for_mission(current_mission).new : Response.find_eager(params[:id])
      # set user_id if this is an observer
      @response.user = current_user if current_user.observer?(current_mission)
      # try to save
      begin
        @response.update_attributes!(params[:response])
        flash[:success] = "Response #{action}d successfully."
        redirect_to(:action => :index)
      rescue ActiveRecord::RecordInvalid
        render_form
      end
    end
    
    def render_form
      @possible_submitters = restrict(User.assigned_to(current_mission))
      @can_mark_reviewed = Permission.can_mark_form_reviewed?(current_user, current_mission)
      @can_choose_submitter = Permission.can_choose_form_submitter?(current_user, current_mission)
      render(:form)
    end
end
