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
    @resp = Response.new(:form_id => 1)
    @place_lookup = PlaceLookup.new
    set_js
  end
  
  def edit
    @resp = Response.find(params[:id], :include => {:answers => :questioning})
    @place_lookup = PlaceLookup.new
    set_js
  end
  
  def update
    @resp = Response.find(params[:id])

    # update the response attribs
    @resp.attributes = params[:response]
    
    # update the place lookup
    @place_lookup = PlaceLookup.find_and_update(params[:place_lookup])
    # update the response place if place_lookup has been used
    (choice = @place_lookup.choice) ? @resp.place = choice : nil
    
    # reject all answer data with no value or option_id set
    params[:answers].reject!{|k,v| v[:value].blank? && v[:option_id].blank?}

    # init a bunch of answer objects based on the passed params
    @resp.update_answers(params[:answers].collect{|k,v| Answer.new(v.merge(:response_id => @resp.id))})
    
    # try to save
    if @resp.save_self_and_answers
      flash[:success] = "Response updated successfully."
      redirect_to(:action => :edit)
    else
      render(:action => :edit)
    end
  end
  private
    def set_js
      @js << 'place_lookups'
    end
end
