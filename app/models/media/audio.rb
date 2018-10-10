# frozen_string_literal: true

module Media
  # Audio-type Answer attachment.
  class Audio < ::Media::Object
    # A note on validation:
    # We no longer validate file extensions because we can't anticipate what extensions folks
    # will be sending from ODK Collect (since the platform changes over time)
    # and there is no easy way to allow the user to correct behavior on validation fail-we just have to
    # discard the file. So for that we reason we limit to mime type validation only since that still
    # provides some security but is less restrictive and less superficial.

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
