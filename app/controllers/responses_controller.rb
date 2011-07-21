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
        rescue ArgumentError
          Rails.logger.error("Form submission error: #{$!.to_s}")
          render(:nothing => true, :status => 500)
        end
      end
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
  end
  
  def edit
    @resp = Response.find_eager(params[:id])
    @place_lookup = PlaceLookup.new
    set_js
  end
  
  def update
    @resp = Response.find(params[:id])

    # update the place lookup
    @place_lookup = PlaceLookup.find_and_update(params[:place_lookup])
    # update the response place if place_lookup has been used
    (p = @place_lookup.choice) ? @resp.place = p : nil
    
    # try to save
    # @resp.save
    begin
      @resp.update_with_answers!(params[:response])
      flash[:success] = "Response updated successfully."
      redirect_to(:action => :edit)
    rescue ActiveRecord::RecordInvalid
      render(:action => :edit)
    end
  end
  private
    def set_js
      @js << 'place_lookups'
    end
end
