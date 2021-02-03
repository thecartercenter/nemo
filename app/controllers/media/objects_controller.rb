# frozen_string_literal: true

module Media
  # Creating, getting, and deleting media attached to responses.
  class ObjectsController < ApplicationController
    load_and_authorize_resource

    def self.media_type(class_name)
      case class_name
      when "Media::Audio" then "audios"
      when "Media::Video" then "videos"
      when "Media::Image" then "images"
      else raise "A valid media class must be specified"
      end
    end

    def create
      media = media_class(params[:type]).new
      media.item.attach(params[:upload])

      if media.save
        # Json keys match hidden input names that contain the key in dropzone form.
        # See ELMO.Views.FileUploaderView for more info.
        render(json: {media_object_id: media.id}, status: :created)
      else
        # Currently there is only one type of validation failure: incorrect content_type.
        # We override this because the default error message is not user friendly.
        msg = I18n.t("errors.file_upload.invalid_format")
        render(json: {errors: [msg]}, status: :unprocessable_entity)
      end
    end

    def destroy
      @object.destroy
      render(body: nil, status: :no_content)
    end

    private

    def media_object_params
      params.require(:media_object).permit(:answer_id, :annotation)
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
