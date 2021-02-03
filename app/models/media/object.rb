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
  # Abstract class for Answer attachments.
  # Need to use ::Media prefix or things break :(
  class ::Media::Object < ApplicationRecord
    belongs_to :answer

    # A note on validation for subclasses:
    # We no longer validate file extensions because we can't anticipate what extensions folks
    # will be sending from ODK Collect (since the platform changes over time)
    # and there is no easy way to allow the user to correct behavior on validation fail-we just have to
    # discard the file. So for that we reason we limit to mime type validation only since that still
    # provides some security but is less restrictive and less superficial.
    has_one_attached :item
    validates :item, attached: true

    delegate :mission, to: :answer
    delegate :response, to: :answer, allow_nil: true

    scope :expired, -> { where(answer_id: nil).where("created_at < ?", 12.hours.ago) }

    after_save :generate_media_object_filename, if: :saved_change_to_answer_id?

    def dynamic_thumb?
      false
    end

    private

    # Set a useful filename to assist data analysts who deal with lots of downloads.
    def generate_media_object_filename
      answer = item.record.answer
      extension = File.extname(item.filename.to_s)
      item.blob.update!(filename: "nemo-#{answer.response.shortcode}-#{answer.id}#{extension}")
    end
  end
end
