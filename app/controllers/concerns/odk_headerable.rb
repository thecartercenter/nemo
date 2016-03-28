module OdkHeaderable
  extend ActiveSupport::Concern

  included do
    skip_authorize_resource only: :odk_headers
    before_action :add_openrosa_headers

    def odk_headers
      authorize! :create, Response
      # For HEAD requests, ODK wants a 204 code with a Location header for some strange reason.
      render(nothing: true, status: 204)
    end
  end

  # adds the appropriate headers for openrosa content
  def add_openrosa_headers
    response.content_type = "text/xml" if request.format.xml?
    response.headers["Location"] = request.original_url if request.method == "HEAD"
    response.headers["X-OpenRosa-Version"] = "1.0"
  end
end
