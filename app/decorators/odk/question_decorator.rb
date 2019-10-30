# frozen_string_literal: true

module Odk
  class QuestionDecorator < ApplicationDecorator
    delegate_all

    URI_DIRS_BY_TYPE = {video: "video", audio: "audio", image: "images", document: "document"}.freeze

    # Make media prompt file name unique to curb collisions and duplications
    def unique_media_prompt_filename
      "#{id}_media_prompt#{File.extname(media_prompt_file_name)}" if media_prompt_file_name
    end

    def media_prompt_md5
      Digest::MD5.file(media_prompt.path).hexdigest if media_prompt_file_name
    end

    def media_prompt_odk_uri
      "jr://#{URI_DIRS_BY_TYPE[media_prompt_type]}/#{unique_media_prompt_filename}"
    end
  end
end
