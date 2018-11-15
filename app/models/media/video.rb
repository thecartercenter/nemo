# frozen_string_literal: true

module Media
  # Video-type Answer attachment.
  class Video < ::Media::Object
    # A note on validation:
    # We no longer validate file extensions because we can't anticipate what extensions folks
    # will be sending from ODK Collect (since the platform changes over time)
    # and there is no easy way to allow the user to correct behavior on validation fail-we just have to
    # discard the file. So for that we reason we limit to mime type validation only since that still
    # provides some security but is less restrictive and less superficial.
    validates_attachment_content_type :item, content_type: [%r{\Avideo/.*\Z}, "application/vnd.ms-asf"]

    def static_thumb_path
      "media/video.png"
    end

    def kind
      "video"
    end
  end
end
