class TagsController < ApplicationController
  skip_authorization_check :only => [:index]

  def index
    @tags = Tag.where("name like ?", params[:q] + '%')
    respond_to do |format|
      format.json { render :json => @tags }
    end
  end

end
