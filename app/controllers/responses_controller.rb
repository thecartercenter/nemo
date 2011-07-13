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
end
