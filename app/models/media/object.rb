# frozen_string_literal: true

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


module Media
  # Abstract class for Answer attachments.
  # Need to use ::Media prefix or things break :(
  class ::Media::Object < ApplicationRecord
    belongs_to :answer

    has_attached_file :item
    validates_attachment_presence :item

    delegate :mission, to: :answer

    scope :expired, -> { where(answer_id: nil).where("created_at < ?", 12.hours.ago) }

    def dynamic_thumb?
      false
    end
  end
end
