module OdkHeaderable
  extend ActiveSupport::Concern

  included do
    skip_authorize_resource only: :odk_headers

    def odk_headers
      authorize! :create, Response
      if request.method == "HEAD"
        # For HEAD requests, ODK wants a 204 code with a Location header for some strange reason.
        response.headers["Location"] = request.original_url
      end

      render(nothing: true, status: 204)
    end
  end

  # adds the appropriate headers for openrosa content
  def render_openrosa
    render(content_type: "text/xml") if request.format.xml?
    response.headers["X-OpenRosa-Version"] = "1.0"
  end
end
