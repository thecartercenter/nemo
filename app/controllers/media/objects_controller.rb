# frozen_string_literal: true

module Media
  # Creating, getting, and deleting media attached to responses.
  class ObjectsController < ApplicationController
    include Storage

    before_action :set_media_object, only: %i[show destroy]
    skip_authorization_check

    def self.media_type(class_name)
      case class_name
      when "Media::Audio" then "audios"
      when "Media::Video" then "videos"
      when "Media::Image" then "images"
      else raise "A valid media class must be specified"
      end
    end

    def show
      style = params[:style] || "original"
      @answer = @media_object.answer
      @response = @answer.try(:response)
      disposition = params[:dl] == "1" ? "attachment" : "inline"

      authorize!(:show, @response) if @response

      send_attachment(@media_object.item,
        style: style, disposition: disposition, filename: media_filename)
    end

    def create
      media = media_class(params[:type]).new
      media.item.attach(params[:upload])
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

    def destroy
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
      extension = File.extname(@media_object.item.filename.to_s)
      if @response && @answer
        "elmo-#{@response.shortcode}-#{@answer.id}#{extension}"
      else
        "elmo-unsaved_response-#{@media_object.id}#{extension}"
      end
    end

    def media_class(type)
      case type
      when "audios" then Media::Audio
      when "videos" then Media::Video
      when "images" then Media::Image
      else raise "A valid media type must be specified"
      end
    end
  end
end
