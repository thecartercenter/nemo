# frozen_string_literal: true

# Removes duplicate stragglers
class DedupeJob < ApplicationJob
  TMP_DUPE_BACKUPS_PATH = Rails.root.join("tmp/odk_dupes_backup")

  def perform
    while Response.dirty_dupe.count.positive?
      response = Response.order(created_at: :asc).dirty_dupe.first
      duplicate_code = duplicate_shortcode(response)
      if duplicate_code.present?
        backup_duplicate_attachments(duplicate_code)
        destroy_duplicate!(duplicate_code)
      else
        clean_up(response)
      end
    end
  end

  private

  def duplicate_shortcode(response)
    blobs = ActiveStorage::Blob.where(checksum: response.blob_checksum)
      .where.not(id: response.odk_xml.blob_id)
    return false if blobs.blank?
    blob = ensure_clean_response(blobs)
    return nil if blob.blank? || unique_user_and_mission?(blob.first, response)
    response.shortcode
  end

  def ensure_clean_response(blobs)
    blobs.map do |b|
      r = Response.where(id: ActiveStorage::Attachment.where(blob_id: b.id).first.record_id)
      next if r.first.blank? || r.first.dirty_dupe
      b
    end.compact
  end

  def unique_user_and_mission?(blob, dirty_response)
    r = Response.find(ActiveStorage::Attachment.where(blob_id: blob.id).first.record_id)
    return if r.nil?
    return false if (r.user_id == dirty_response.user_id) && (r.mission_id == dirty_response.mission_id)
    true
  end

  def backup_duplicate_attachments(dupe_code)
    dupe_response = Response.where(shortcode: dupe_code).first
    attachment = ActiveStorage::Attachment.where(record_id: dupe_response.id).first
    FileUtils.mkdir_p(TMP_DUPE_BACKUPS_PATH)

    media_objects = Media::Object.where(answer_id: dupe_response.answer_ids)

    copy_files(xml: attachment, media: media_objects)
  end

  def copy_files(files)
    File.open("#{TMP_DUPE_BACKUPS_PATH}/#{files[:xml].filename}", "w") do |f|
      files[:xml].download { |chunk| f.write(chunk) }
    end

    files[:media].each do |m|
      File.open("#{TMP_DUPE_BACKUPS_PATH}/#{m.item.filename}", "wb") do |f|
        m.item.download { |chunk| f.write(chunk) }
      end
    end
  end

  def destroy_duplicate!(dupe_code)
    ResponseDestroyer.new(scope: Response.where(shortcode: dupe_code)).destroy!
  end

  def clean_up(response)
    response.dirty_dupe = false
    response.save!
  end
end
