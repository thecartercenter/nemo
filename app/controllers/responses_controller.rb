class ResponsesController < ApplicationController
  def create
    if request.format == Mime::XML
      if request.method == "HEAD"
        # just render the 'no content' status since that's what odk wants!
        render(:nothing => true, :status => 204)
      elsif upfile = params[:xml_submission_file]
        begin
          contents = upfile.read
          Rails.logger.debug("Form data: " + contents)
          Response.create_from_xml(contents, current_user)
          render(:nothing => true, :status => 201)
        rescue ArgumentError, ActiveRecord::RecordInvalid
          msg = "Form submission error: #{$!.to_s}"
          Rails.logger.error(msg)
          render(:nothing => true, :status => 500)
        end
      end
    else
      crupdate
    end
  end
  
  def index
    # find or create a subindex object
    @subindex = Subindex.find_and_update(session, current_user, "Response", params[:page])
    # get the responses
    begin
      @responses = Response.sorted(@subindex.params)
    rescue SearchError
      flash[:error] = $!.to_s
      @responses = Response.sorted(:page => 1)
    end
  end
  
  def new
    form = Form.find(params[:form_id]) rescue nil
    flash[:error] = "You must choose a form to edit." and redirect_to(:action => :index) unless form
    @resp = Response.new(:form => form)
    @place_lookup = PlaceLookup.new
    set_js
  end
  
  def edit
    @resp = Response.find_eager(params[:id])
    @place_lookup = PlaceLookup.new
    set_js
  end
  
  def show
    @resp = Response.find_eager(params[:id])
  end
  
  def update
    crupdate
  end
  
  def destroy
    @resp = Response.find(params[:id])
    @resp.destroy and flash[:success] = "Response deleted successfully" rescue flash[:error] = $!.to_s
    redirect_to(:action => :index)
  end
  
  private
    def crupdate
      action = params[:action]
      # find or create the response
      @resp = action == "create" ? Response.new : Response.find(params[:id])
      # set user_id if this is an observer
      @resp.user = current_user if current_user.is_observer?
      # update the place lookup
      @place_lookup = PlaceLookup.find_and_update(params[:place_lookup])
      # update the response place if place_lookup has been used
      (p = @place_lookup.choice) ? @resp.place = p : nil
      # try to save
      begin
        @resp.update_attributes!(params[:response])
        flash[:success] = "Response #{action}d successfully."
        redirect_to(edit_response_path(@resp))
      rescue ActiveRecord::RecordInvalid
        set_js
        render(:action => action == "create" ? :new : :edit)
      end
    end
    
    def set_js
      @js << 'place_lookups'
    end
end
