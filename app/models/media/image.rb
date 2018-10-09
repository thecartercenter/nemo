# frozen_string_literal: true

module Media
  # Image-type Answer attachment.
  class Image < ::Media::Object
    # We override the has_attached_file declaration here to provide styles.
    has_attached_file :item, styles: {normal: "720x720>", thumb: "100x100#"}

    validates_attachment_content_type :item, content_type: %r{\Aimage/.*\Z}

    def thumb_path
      token_url(style: :thumb)
    end

    def kind
      "image"
    end
  end
end
