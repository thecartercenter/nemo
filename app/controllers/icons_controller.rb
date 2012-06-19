class IconsController < ApplicationController

  def show
    # generate (or locate in the cache) the image and get its path
    image_url = Icon.generate("#" + params[:color])
    
    # set content types for direct image download
    response.headers['Content-Type'] = 'image/png'
    response.headers['Content-Disposition'] = 'inline'
    
    # render the binary contents of the image
    render :text => open(image_url).read
  end

end
