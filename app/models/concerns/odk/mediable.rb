# frozen_string_literal: true

module Odk
  # Code related to storing media files that are intended to be sent to and viewed in ODK Collect.
  module Mediable
    extend ActiveSupport::Concern

    # video/ogg is needed for audio OGG files for some weird reason.
    ODK_MEDIA_MIME_TYPES = %w[audio/mpeg audio/ogg audio/wave audio/wav audio/x-wav audio/x-pn-wav
                              audio/flac video/ogg application/ogg video/mp4 image/png image/jpeg].freeze
    ODK_MEDIA_EXTS = {audio: %w[mp3 ogg wav flac], video: %w[mp4], image: %w[png jpg jpeg]}.freeze

    class_methods do
      def odk_media_attachment(col_name)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          has_attached_file :#{col_name}

          # The purpose of these validations is twofold:
          # 1. to prevent malicious content from being uploaded to the server (e.g. executable code)
          # 2. to prevent people from uploading content that won't be playable on an Android device
          # #1 is mostly handled by content type validation and #2 is mostly handled by extension validation.
          # We don't care too much if people upload e.g. a video with the wrong extension. This may sneak
          # through the validations (e.g. an ogg video file with an .ogg extension (should be .ogv))
          # and it may not play back properly but this should be rare and is not a security risk.
          # Executable code should definitely be caught by the content type validation.
          validates_attachment_content_type :#{col_name}, content_type: ODK_MEDIA_MIME_TYPES,
                                                          message: :invalid_type
          validates_attachment_file_name :#{col_name},
            matches: /\\.(#{ODK_MEDIA_EXTS.values.flatten.join('|')})\\Z/i, message: :invalid_type

          def #{col_name}?
            #{col_name}_file_name.present?
          end

          def #{col_name}_type
            return nil unless #{col_name}?
            extension = File.extname(#{col_name}_file_name)[1..-1]
            @#{col_name}_media_type ||= ODK_MEDIA_EXTS.map do |type, exts|
              type if exts.include?(extension)
            end.compact.first
          end
        RUBY
      end
    end
  end
end
