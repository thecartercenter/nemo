# frozen_string_literal: true

class Media::ObjectsController < ApplicationController
  before_action :set_media_object, only: %i[show delete]
  skip_authorization_check

  def show
    style = params[:style]
    @answer = @media_object.answer
    @response = @answer.try(:response)
    disposition = params[:dl] == "1" ? "attachment" : "inline"

    if @response
      authorize!(:show, @response)
    elsif @media_object.token != params[:token]
      raise CanCan::AccessDenied.new("Not authorized", :view, :media_object)
    end

    send_file(@media_object.item.path(style),
      type: @media_object.item_content_type,
      disposition: disposition,
      filename: media_filename)
  end

  def create
    media = media_class(params[:type]).new(item: params[:upload])
    # answer_id can be blank because creation is asynchronous and
    # will be assigned when the response is submitted
    media.answer = Answer.find(params[:answer_id]) if params[:answer_id]

    if media.save
      # Json keys match hidden input names that contain the key in dropzone form.
      # See ELMO.Views.FileUploaderView for more info.
      render(json: {media_object_id: media.id}, status: :created)
    else
      # Currently there is only one type of validation failure: incorrect type.
      # The default paperclip error messages are heinous, which is why we're doing this.
      msg = I18n.t("errors.file_upload.invalid_format")
      render(json: {errors: [msg]}, status: :unprocessable_entity)
    end
  end

  def delete
    @media_object.destroy
    render(body: nil, status: :no_content)
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
    if @response && @answer
      "elmo-#{@response.shortcode}-#{@answer.id}#{extension}"
    else
      "elmo-unsaved_response-#{@media_object.id}#{extension}"
    end
  end

  def media_class(type)
    case type
    when "audios"
      Media::Audio
    when "videos"
      Media::Video
    when "images"
      Media::Image
    else
      raise "A valid media type must be specified"
    end
  end
end
