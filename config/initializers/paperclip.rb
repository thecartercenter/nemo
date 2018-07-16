Paperclip::Attachment.default_options.merge!(
  path: ":rails_root/uploads/:class/:attachment/:id_partition/:style/:filename",
  url: "/:locale/m/:mission/:class/:id/:style"
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

module Paperclip
  module Interpolations
    # Returns the id of the instance in a split path form. e.g. returns
      # 000/001/234 for an id of 1234.
      def id_partition attachment, style_name
        case id = attachment.instance.id
        when Integer
          ("%09d".freeze % id).scan(/\d{3}/).join("/".freeze)
        when String
          id.split("-".freeze).join("/".freeze)
        else
          nil
        end
      end
  end
end
