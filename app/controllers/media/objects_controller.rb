class Media::ObjectsController < ApplicationController
  before_action :set_media_object, only: [:show, :edit, :update, :destroy]
  skip_authorization_check

  def show
    style = params[:style]
    @answer = @media_object.answer
    @response = @answer.response

    send_file @media_object.item.path(style),
      type: @media_object.item_content_type,
      disposition: "attachment",
      filename: media_filename
  end

  private

  def set_media_object
    @media_object = Media::Object.find(params[:id])
  end

  def media_object_params
    params.require(:media_object).permit(:answer_id, :annotation)
  end

  def media_filename
    extension = File.extname(@media_object.item_file_name)
    "elmo-#{@response.id}-#{@answer.id}#{extension}"
  end
end
