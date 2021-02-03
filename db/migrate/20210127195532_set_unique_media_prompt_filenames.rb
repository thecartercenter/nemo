# frozen_string_literal: true

# Ensure a unique filename to curb collisions on ODK.
class SetUniqueMediaPromptFilenames < ActiveRecord::Migration[6.0]
  def up
    attachments = ActiveStorage::Attachment.where(record_type: "Question")
    attachments.each do |attachment|
      extension = File.extname(attachment.filename.to_s)
      attachment.blob.update!(filename: "#{attachment.record_id}_media_prompt#{extension}")
    end
  end
end
