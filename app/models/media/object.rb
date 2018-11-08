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

    before_save :generate_token

    scope :expired, -> { where(answer_id: nil).where("created_at < ?", 12.hours.ago) }

    private

    # We need to create a persisted token to use for authorization
    # because when a response fails to save with a media object uploaded
    # the media object is persisted with no reference back to the response
    # and no way to check if you're authorized to see it.
    #
    # Storing the token with the object and authorizing against it
    # keeps a user from spoofing the URL to see unauthorized media
    def generate_token
      self.token = SecureRandom.hex
    end
  end
end
