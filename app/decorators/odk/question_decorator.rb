# frozen_string_literal: true

module ODK
  class QuestionDecorator < ApplicationDecorator
    delegate_all

    URI_DIRS_BY_TYPE = {video: "video", audio: "audio", image: "images"}.freeze

    def media_prompt_odk_uri
      "jr://#{URI_DIRS_BY_TYPE[media_prompt_type]}/#{media_prompt.filename}"
    end
  end
end
