module OdkHeaderable
  extend ActiveSupport::Concern

  included do
    skip_authorize_resource only: :odk_headers
    before_action :add_openrosa_headers
  end

  def odk_headers
    authorize! :create, Response
    render(body: nil, status: 204)
  end

  private
  # adds the appropriate headers for openrosa content
  def add_openrosa_headers
    response.content_type = "text/xml" if request.format.xml?
    # For HEAD requests, ODK wants a Location header for some strange reason.
    response.headers["Location"] = request.original_url if request.method == "HEAD"
    response.headers["X-OpenRosa-Version"] = "1.0"
  end
end
