# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# == Schema Information
#
# Table name: media_objects
#
#  id                :uuid             not null, primary key
#  item_content_type :string(255)      not null
#  item_file_name    :string(255)      not null
#  item_file_size    :integer          not null
#  item_updated_at   :datetime         not null
#  type              :string(255)      not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  answer_id         :uuid
#
# Indexes
#
#  index_media_objects_on_answer_id  (answer_id)
#
# Foreign Keys
#
#  media_objects_answer_id_fkey  (answer_id => answers.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Metrics/LineLength

module Media
  # Document-type Answer attachment.
  class Document < ::Media::Object
    # A note on validation:
    # We no longer validate file extensions because we can't anticipate what extensions folks
    # will be sending from ODK Collect (since the platform changes over time)
    # and there is no easy way to allow the user to correct behavior on validation fail-we just have to
    # discard the file. So for that we reason we limit to mime type validation only since that still
    # provides some security but is less restrictive and less superficial.
    validates_attachment_content_type :item, content_type: [
      "text/csv", "text/plain", "application/pdf", "application/rtf",
      "application/msword", "application/vnd.ms-excel", "application/vnd.ms-powerpoint",
      "application/vnd.oasis.opendocument.spreadsheet", "application/vnd.oasis.opendocument.text",
      "application/vnd.oasis.opendocument.presentation",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      # sometimes mimemagic returns x-ole-storage for msoffice files: https://github.com/minad/mimemagic/issues/50
      "application/x-ole-storage"
    ]

    def static_thumb_path
      "media/document.png"
    end

    def kind
      "document"
    end
  end
end
