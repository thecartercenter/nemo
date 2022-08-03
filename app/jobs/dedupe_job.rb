# frozen_string_literal: true

# Removes duplicate stragglers
class DedupeJob < ApplicationJob
  TMP_DUPE_BACKUPS_PATH = Rails.root.join("tmp/odk_dupes_backup")

  def perform
    dirty_responses = Response.order(created_at: :desc).dirty_dupe.to_a

    dirty_responses.each do |response|
      if duplicate?(response)
        backup_duplicate_attachments(response)
        destroy_duplicate!(response)
      end
    end

    clean_up(dirty_responses)
  end

  private

  def duplicate?(response)
    blob = ActiveStorage::Blob.where(checksum: response.odk_xml.checksum)
      .where.not(id: response.odk_xml.blob_id).first
    return false if blob.blank?
    blob_response = Response.find_by(id: ActiveStorage::Attachment.find_by(blob_id: blob.id).record_id)

    return false if blob_response.blank? || unique_user_and_mission?(blob_response, response)
    true
  end

  def unique_user_and_mission?(blob_response, dirty_response)
    return false if blob_response.user_id == dirty_response.user_id
    return false if blob_response.mission_id == dirty_response.mission_id
    true
  end

  # create
  def backup_duplicate_attachments(dupe)
    attachment = ActiveStorage::Attachment.find_by(record_id: dupe.id)
    media_objects = Media::Object.where(answer_id: dupe.answer_ids)
    copy_files(xml: attachment, media: media_objects)
  end

  def copy_files(files)
    # write to json
    FileUtils.mkdir_p(TMP_DUPE_BACKUPS_PATH)

    File.open("#{TMP_DUPE_BACKUPS_PATH}/#{files[:xml].filename}", "w") do |f|
      files[:xml].download { |chunk| f.write(chunk) }
    end

    files[:media].each do |m|
      File.open("#{TMP_DUPE_BACKUPS_PATH}/#{m.item.filename}", "wb") do |f|
        m.item.download { |chunk| f.write(chunk) }
      end
    end
  end

  def destroy_duplicate!(dupe)
    # dupe.odk_xml.purge
    ResponseDestroyer.new(scope: Response.where(shortcode: dupe.shortcode)).destroy!
    Sentry.capture_message("Destroyed duplicate response in DedupeJob")
  end

  def clean_up(responses)
    Response.where(id: responses).update_all(dirty_dupe: false)
  end
end
