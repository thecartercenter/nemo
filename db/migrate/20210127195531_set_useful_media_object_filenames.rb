# frozen_string_literal: true

class SetUsefulMediaObjectFilenames < ActiveRecord::Migration[6.0]
  def up
    attachments = ActiveStorage::Attachment.where(record_type: "Media::Object")
    attachments.includes(record: {answer: :response}).each do |attachment|
      attachment.blob.update!(filename: media_filename(attachment))
    end
  end
end

def media_filename(attachment)
  media_object = attachment.record
  answer = media_object.answer
  extension = File.extname(attachment.filename.to_s)
  if answer
    "elmo-#{answer.response.shortcode}-#{answer.id}#{extension}"
  else
    # This could happen e.g. if you upload a file to the web form but then don't submit it.
    "elmo-unsaved_response-#{media_object.id}#{extension}"
  end
end
