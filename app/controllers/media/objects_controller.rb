class Media::ObjectsController < ApplicationController
  before_action :set_media_object, only: [:show, :edit, :update, :delete]
  skip_authorization_check

  def show
    style = params[:style]
    @answer = @media_object.answer
    @response = @answer.response
    disposition = (params[:dl] == "1") ? "attachment" : "inline"
    authorize! :show, @response

    send_file @media_object.item.path(style),
      type: @media_object.item_content_type,
      disposition: disposition,
      filename: media_filename
  end

  def create
    media = media_class(params[:type]).new(item: params[:upload])
    # answer_id can be blank because creation is asynchronous and will be assigned when the response is submitted
    media.answer = Answer.find(params[:answer_id]) if params[:answer_id]

    if media.save
      render json: { id: media.id }, status: 201
    else
      render json: { error: media.errors }, status: 422
    end
  end

  def delete
    @media_object.destroy
    render nothing: true, status: 204
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

  def media_class(type)
    case type
    when 'audio'
      return Media::Audio
    when 'video'
      return Media::Video
    when 'image'
      return Media::Image
    else
      raise "A valid media type must be specified"
    end
  end
end
