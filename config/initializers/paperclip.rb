# frozen_string_literal: true

Paperclip::Attachment.default_options.merge!(
  path: ":rails_root/uploads/:class/:attachment/:id_partition/:style/:filename",
  url: "/:locale/m/:mission/:class/:id/:style"
)

Paperclip.options[:content_type_mappings] = {
  wmv: "application/vnd.ms-asf",
  opus: "audio/x-opus+ogg"
}

Paperclip.interpolates(:mission) do |attachment, _style|
  attachment.instance.mission.compact_name
end

Paperclip.interpolates(:locale) do |_attachment, _style|
  I18n.locale
end

module Paperclip
  # Paperclip spoof detection currently, as a result of idiosyncracies with the `file` command,
  # reports false positives for a variety of different media types and must be disabled.
  # TODO: Find a better workaround, or wait for paperclip to update
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end

  # Returns the id of the instance in a split path form. e.g. returns
  # 000/001/234 for an id of 1234.
  module Interpolations
    def id_partition(attachment, _style_name)
      case id = attachment.instance.id
      when Integer
        format("%09d", id).scan(/\d{3}/).join("/")
      when String
        id.split("-").join("/")
      end
    end
  end
end
