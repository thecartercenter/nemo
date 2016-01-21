class Media::ObjectsController < ApplicationController
  before_action :set_media_object, only: [:show, :edit, :update, :destroy]
  skip_authorization_check

  # GET /media/objects/1
  # GET /media/objects/1.json
  def show
    style = params[:style]
    send_file @media_object.item.path(style), type: @media_object.item_content_type, disposition: 'inline'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_media_object
      @media_object = Media::Object.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def media_object_params
      params.require(:media_object).permit(:answer_id, :annotation)
    end
end
