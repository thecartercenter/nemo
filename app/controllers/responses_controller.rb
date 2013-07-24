class ResponsesController < ApplicationController
  # need to load with associations for show and edit
  before_filter :load_with_associations, :only => [:show, :edit]
  
  # authorization via CanCan
  load_and_authorize_resource

  def index
    # handle different formats
    respond_to do |format|
      # html is the normal index page
      format.html do
        # apply search and pagination
        params[:page] ||= 1
        @responses = apply_filters(@responses)
        
        # include answers so we can show key questions
        @responses = @responses.includes(:answers)
        
        # get list of published forms for 'create response' link
        @pubd_forms = Form.accessible_by(current_ability).published
        
        # render just the table if this is an ajax request
        render(:partial => "table_only", :locals => {:responses => @responses}) if ajax_request?
      end
      
      # csv output is for exporting responses
      format.csv do
        # get the response, for export, but not paginated
        @responses = Response.for_export(apply_filters(@responses, :pagination => false))

        # render the csv
        render_csv("Responses")
      end
    end
  end

  def show
    prepare_and_render_form
  end
  
  def new
    # get the form specified in the params and error if it's not there
    begin
      @response.form = Form.with_questionings.find(params[:form_id])
    rescue ActiveRecord::RecordNotFound
      # this should not be possible
      flash[:error] = "no form selected"
      return redirect_to(:action => :index)
    end
    
    # render the form template
    prepare_and_render_form
  end
  
  def edit
    prepare_and_render_form
  end
  
  def create
    # if this is a submission from ODK collect
    if request.format == Mime::XML
      
      # if the method is HEAD or GET just render the 'no content' status since that's what odk wants!
      if %w(HEAD GET).include?(request.method)
        render(:nothing => true, :status => 204)
      
      # otherwise, we should process the xml submission
      elsif upfile = params[:xml_submission_file]
        begin
          contents = upfile.read
          
          # set the user_id to current user
          @response.user_id = current_user.id
          
          # parse the xml stuff
          @response.populate_from_xml(contents)
          
          # save without validating, as we have no way to present validation errors to user, and ODK already does validation
          @response.save(:validate => false)
          
          # ODK wants a blank response with code 201 on success
          render(:nothing => true, :status => 201)
        rescue ArgumentError
          # if we catch an error, render 404 code
          render(:nothing => true, :status => 404)
        end
      end
      
    # for HTML format just use the method below
    else
      web_create_or_update
    end
  end
  
  def update
    @response.assign_attributes(params[:response])
    web_create_or_update
  end
  
  def destroy
    destroy_and_handle_errors(@response)
    redirect_to(:action => :index)
  end
  
  private
    # loads the response with its associations
    def load_with_associations
      @response = Response.with_associations.find(params[:id])
    end
    
    # handles creating/updating for the web form
    def web_create_or_update
      # set source/modifier to web
      params[:response][:source] = "web" if params[:action] == "create"
      params[:response][:modifier] = "web"

      # check for "update and mark as reviewed"
      params[:response][:reviewed] = true if params[:commit_and_mark_reviewed]
      
      # try to save
      begin
        @response.save!
        set_success_and_redirect(@response)
      rescue ActiveRecord::RecordInvalid
        prepare_and_render_form
      end
    end
    
    # prepares objects for and renders the form template
    def prepare_and_render_form
      # get the users to which this response can be assigned
      @possible_submitters = User.accessible_by(current_ability).assigned_to(current_mission)
      
      # render the form
      render(:form)
    end
end
