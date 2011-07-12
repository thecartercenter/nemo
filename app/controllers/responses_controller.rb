class ResponsesController < ApplicationController
  def create
    if request.format == Mime::XML
      if request.method == "HEAD"
        render(:nothing => true, :status => 204)
      elsif upfile = params[:xml_submission_file]
        render(:status => 201)
      end
    end
  end
end
