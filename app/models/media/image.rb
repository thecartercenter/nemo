class Media::Image < Media::Object
  has_attached_file :item, styles: {
    normal: '720x720>',
    thumb: '100x100#'
  }
  validates_attachment_content_type :item, content_type: %r{\Aimage/.*\Z}
  validates_attachment_file_name :item, matches: /\.(png|jpe?g)\Z/

  def thumb_path
    url(:thumb)
  end
end
