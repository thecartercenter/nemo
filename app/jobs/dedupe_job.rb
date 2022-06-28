# frozen_string_literal: true

# Removes duplicate stragglers
class DedupeJob < ApplicationJob

  TMP_DUPE_BACKUPS_PATH = Rails.root.join("tmp/odk_dupes_backup")

  def perform
    backup_duplicate_xml
    destroy_duplicates!
    clean_up
  end

  private

  def dupe_codes
    return false if Response.dirty_dupe.empty?
    @dupe_codes ||= tuples.group_by { |t| t[3] }.values.reject { |set| set.size < 2 }
                           .map { |set| set[1..].map { |t| t[0] } }.flatten
  end

  def tuples
    @tuples ||= ActiveStorage::Attachment.where(record_id: Response.dirty_dupe.map(&:id))
                                         .where(record_type: "Response")
                                         .includes(record: :user)
                                         .order(created_at: :desc)
                                         .filter { |attachment| attachment.record.presence }.map do |attachment|
      response = attachment.record
      [response.shortcode, response.created_at, response.user.name, attachment.checksum, response.mission_id]
    end.compact
  end

  def backup_duplicate_xml
    # see submission error, save to tmp/duplicates
    puts "dupe codes #{dupe_codes}"
    dupe_responses = Response.where(shortcode: dupe_codes).map(&:id)
    attachments = ActiveStorage::Attachment.where(record_id: dupe_responses)
    FileUtils.mkdir_p(TMP_DUPE_BACKUPS_PATH)
    attachments.each do |a|
      copy_attachment(a)
    end
  end

  def copy_attachment(attachment)
    File.open("#{TMP_DUPE_BACKUPS_PATH}/#{attachment.filename}", "w") do |f|
      puts "downloading file #{TMP_DUPE_BACKUPS_PATH}/#{attachment.filename}"
      attachment.download { |chunk| f.write(chunk) }
    end
  rescue StandardError => e
    Rails.logger.debug(e.message)
    ExceptionNotifier.notify_exception(e, data: {response: attachment.filename.to_s})
  end

  def destroy_duplicates!
    ResponseDestroyer.new(scope: Response.where(shortcode: dupe_codes)).destroy!
  end

  def clean_up
    Response.dirty_dupe.each do |r|
      r.dirty_dupe = false
      r.save!
    end
  end
end
