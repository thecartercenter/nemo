class Media::Audio < Media::Object
  validates_attachment_content_type :item, content_type: [%r{\Aaudio/.*\Z}, 'video/webm']
  validates_attachment_file_name :item, matches: /\.(mp3|ogg|webm|wav)\Z/i

  def thumb_path
    "media/audio.png"
  end

  def kind
    "audio"
  end
end
