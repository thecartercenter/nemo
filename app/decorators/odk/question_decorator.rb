# frozen_string_literal: true

module Odk
  class QuestionDecorator < ApplicationDecorator
    delegate_all

    # Make audio prompt file name unique to curb collisions and duplications
    def unique_audio_prompt_filename
      "#{id}_audio_prompt#{File.extname(audio_prompt_file_name)}" if audio_prompt_file_name
    end

    def audio_prompt_md5
      Digest::MD5.file(audio_prompt.path).hexdigest if audio_prompt_file_name
    end
  end
end
