# frozen_string_literal: true

class SavedUpload < ApplicationRecord
  has_attached_file :file
  validates_attachment_presence :file
  do_not_validate_attachment_file_type :file

  scope :old, -> { where('created_at < ?', 30.days.ago) }

  def self.cleanup_old_uploads
    old.destroy_all
  end
end
