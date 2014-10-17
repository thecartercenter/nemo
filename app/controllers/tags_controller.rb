class TagsController < ApplicationController
  skip_authorization_check :only => [:index]

  def index
    @tags = Tag.where("name like ?", "%#{params[:q]}%").select([:id, :name])
    respond_to do |format|
      format.json { render json: @tags.as_json }
    end
  end

end
