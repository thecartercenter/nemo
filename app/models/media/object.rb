# frozen_string_literal: true

module Media
  # Abstract class for Answer attachments.
  # Need to use ::Media prefix or things break :(
  class ::Media::Object < ApplicationRecord
    acts_as_paranoid

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
