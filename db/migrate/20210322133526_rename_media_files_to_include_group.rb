# frozen_string_literal: true

class RenameMediaFilesToIncludeGroup < ActiveRecord::Migration[6.1]
  def up
    attachments = ActiveStorage::Attachment.where(record_type: "Media::Object")
    attachments.includes(record: {answer: :response}).each do |attachment|
      media_object = attachment.record
      media_object.generate_media_object_filename if media_object.present?
    end
  end
end
