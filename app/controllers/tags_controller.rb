class TagsController < ApplicationController
  skip_authorization_check :only => [:suggest]

  def suggest
    @tags = Tag.suggestions(current_mission, params[:q])
    respond_to do |format|
      format.json { render json: @tags.as_json }
    end
  end

end
