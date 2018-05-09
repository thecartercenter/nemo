# frozen_string_literal: true

class Media::Audio < Media::Object
  # For some reason, the mime-magic gem returns video/ogg for audio OGG files. Same for WEBM.
  validates_attachment_content_type :item, content_type: [%r{\Aaudio/.*\Z}, "video/ogg", "video/webm"]
  validates_attachment_file_name :item, matches: /\.(mp3|ogg|webm|wav)\Z/i

  def thumb_path
    "media/audio.png"
  end

  def kind
    "audio"
  end
end
