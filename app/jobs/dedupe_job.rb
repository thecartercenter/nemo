# frozen_string_literal: true

# Removes duplicate stragglers
class DedupeJob < ApplicationJob
  TMP_DUPE_BACKUPS_PATH = Rails.root.join("tmp/odk_dupes_backup")

  def perform
    while Response.dirty_dupe.count.positive?
      response = Response.order(created_at: :asc).dirty_dupe.first
      duplicate_code = duplicate_shortcode(response)
      if duplicate_code.present?
        backup_duplicate_xml(duplicate_code)
        destroy_duplicate!(duplicate_code)
      else
        clean_up(response)
      end
    end
  end

  private

  def duplicate_shortcode(response)
    blobs = ActiveStorage::Blob.where(checksum: response.blob_checksum).where.not(id: response.odk_xml.blob_id)
    return false if blobs.blank?
    blob = ensure_clean_response(blobs)
    return nil if blob.blank?
    return nil if unique_user_and_mission?(blob.first, response)
    response.shortcode
  end

  def ensure_clean_response(blobs)
    blobs.map do |b|
      r = Response.where(id: ActiveStorage::Attachment.where(blob_id: b.id).first.record_id)
      next if r.first.blank?
      next if r.first.dirty_dupe
      b
    end.compact
  end

  def unique_user_and_mission?(blob, dirty_response)
    r = Response.find(ActiveStorage::Attachment.where(blob_id: blob.id).first.record_id)
    return if r.nil?
    if (r.user_id == dirty_response.user_id) && (r.mission_id == dirty_response.mission_id)
      return false
    end
    true
  end

  def backup_duplicate_xml(dupe_code)
    # see submission error, save to tmp/duplicates
    dupe_response = Response.where(shortcode: dupe_code).first
    attachment = ActiveStorage::Attachment.where(record_id: dupe_response.id).first
    FileUtils.mkdir_p(TMP_DUPE_BACKUPS_PATH)
    copy_attachment(attachment)
  end

  def copy_attachment(attachment)
    File.open("#{TMP_DUPE_BACKUPS_PATH}/#{attachment.filename}", "w") do |f|
      attachment.download { |chunk| f.write(chunk) }
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
