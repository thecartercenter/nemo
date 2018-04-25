# frozen_string_literal: true

# MarkersController
class MarkersController < ApplicationController
  # authorization via cancan
  load_and_authorize_resource

  def show
    # generate (or locate in the cache) the image and get its path
    image_url = Marker.generate(params[:color])

    # set content types for direct image download
    response.headers["Content-Type"] = "image/png"
    response.headers["Content-Disposition"] = "inline"

    # render the binary contents of the image
    render text: open(image_url).read
  end
end
