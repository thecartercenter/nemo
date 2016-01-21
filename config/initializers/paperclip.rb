Paperclip::Attachment.default_options.merge!(
  path: ':rails_root/uploads/:class/:attachment/:id_partition/:style/:filename',
  url: '/uploads/:class/:id/:style'
)

Paperclip.options[:content_type_mappings] = {
  wmv: 'application/vnd.ms-asf',
  opus: 'audio/x-opus+ogg'
}

module Paperclip
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end
end
