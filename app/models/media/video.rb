class Media::Video < Media::Object
  validates_attachment_content_type :item, content_type: [%r{\Avideo/.*\Z}, 'application/vnd.ms-asf']
  validates_attachment_file_name :item, matches: /\.(3gp|mp4|webm|mpe?g|wmv|avi)\Z/i

  def thumb_path
    "media/video.png"
  end

  def kind
    "video"
  end
end
