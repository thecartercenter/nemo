# frozen_string_literal: true

module ODK
  class QuestionDecorator < ApplicationDecorator
    delegate_all

    URI_DIRS_BY_TYPE = {video: "video", audio: "audio", image: "images"}.freeze

    # Make media prompt filename unique to curb collisions and duplications,
    # maintaining the extension e.g. ".mp3"
    def unique_media_prompt_filename
      "#{id}_media_prompt#{File.extname(media_prompt.filename.to_s)}" if media_prompt?
    end

    def media_prompt_md5
      media_prompt.checksum if media_prompt?
    end

    def media_prompt_odk_uri
      "jr://#{URI_DIRS_BY_TYPE[media_prompt_type]}/#{unique_media_prompt_filename}"
    end
  end
end
