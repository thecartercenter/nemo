# frozen_string_literal: true

# rubocop:disable Layout/LineLength
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
# rubocop:enable Layout/LineLength

module Media
  # Audio-type Answer attachment.
  class Audio < ::Media::Object
    # The list of types here is those we expect to be captured by an Android phone.
    # For some reason, the mime-magic gem returns video/ogg for audio OGG files. Same for WEBM.
    # See parent class comments for more info.
    validates :item, content_type: [%r{\Aaudio/.*\z}, "video/ogg", "video/webm"]

    def static_thumb_path
      "media/audio.png"
    end

    def kind
      "audio"
    end
  end
end
