# frozen_string_literal: true

module Odk
  class QuestionDecorator < ApplicationDecorator
    delegate_all

    # Make media prompt file name unique to curb collisions and duplications
    def unique_media_prompt_filename
      "#{id}_media_prompt#{File.extname(media_prompt_file_name)}" if media_prompt_file_name
    end

    def media_prompt_md5
      Digest::MD5.file(media_prompt.path).hexdigest if media_prompt_file_name
    end
  end
end
