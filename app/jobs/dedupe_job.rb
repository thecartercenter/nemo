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
    matching_blobs = ActiveStorage::Blob.where(checksum: response.odk_xml.checksum)
      .where.not(id: response.odk_xml.blob_id)
    return false if matching_blobs.blank?

    matching_attachments = ActiveStorage::Attachment.where(blob_id: matching_blobs.pluck(:id))
    matching_responses = Response.where(id: matching_attachments.pluck(:record_id),
                                        mission_id: response.mission_id, user_id: response.user_id)
    matching_responses.present?
  end

  def backup_duplicate_attachments(dupe)
    xml_attachment = ActiveStorage::Attachment.find_by(record_id: dupe.id)
    media_objects = Media::Object.where(answer_id: dupe.answer_ids)
    copy_files(response: dupe, xml: xml_attachment, media: media_objects)
  end

  def copy_files(response:, xml:, media:)
    FileUtils.mkdir_p(TMP_DUPE_BACKUPS_PATH)

    dupe_json = {
      form_id: response.form_id,
      odk_xml: xml.blob_id
    }

    media.each do |m|
      qing_id = m.answer.questioning_id
      dupe_json["qing#{qing_id}"] = m.item.blob_id
    end

    File.open("#{TMP_DUPE_BACKUPS_PATH}/#{response.id}.json", "w") do |file|
      file.write(dupe_json.to_json)
    end
  end

  def destroy_duplicate!(dupe)
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "Shortcode: #{dupe.shortcode}"))
    Sentry.capture_message("Destroying duplicate response")
    ResponseDestroyer.new(scope: Response.where(shortcode: dupe.shortcode)).destroy!
  end

  def clean_up(responses)
    Response.where(id: responses).update_all(dirty_dupe: false)
  end
end
