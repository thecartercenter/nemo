# frozen_string_literal: true

module Media
  # Video-type Answer attachment.
  class Video < ::Media::Object
    validates_attachment_content_type :item, content_type: [%r{\Avideo/.*\Z}, "application/vnd.ms-asf"]

    def thumb_path
      "media/video.png"
    end

    def kind
      "video"
    end
  end
end
