Paperclip::Attachment.default_options.merge!(
  path: ":rails_root/uploads/:class/:attachment/:id_partition/:style/:filename",
  url: "/uploads/:class/:id/:style"
)

Paperclip.options[:content_type_mappings] = {
  wmv: "application/vnd.ms-asf",
  opus: "audio/x-opus+ogg"
}

# Paperclip spoof detection currently, as a result of idiosyncracies with the `file` command,
# reports false positives for a variety of different media types and must be disabled.
# TODO: Find a better workaround, or wait for paperclip to update
module Paperclip
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end
end
