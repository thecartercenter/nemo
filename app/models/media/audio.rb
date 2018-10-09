# frozen_string_literal: true

module Media
  # Audio-type Answer attachment.
  class Audio < ::Media::Object
    # For some reason, the mime-magic gem returns video/ogg for audio OGG files. Same for WEBM.
    validates_attachment_content_type :item, content_type: [%r{\Aaudio/.*\Z}, "video/ogg", "video/webm"]

    def thumb_path
      "media/audio.png"
    end

    def kind
      "audio"
    end
  end
end
