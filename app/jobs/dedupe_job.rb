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
    # Make hashtable with checksum as key, reject sets where there is only 1
    @dupe_checksums ||= tuples.group_by { |t| t[3] }.values.reject { |set| set.size < 2 }
    @dupe_codes ||= check_unique_users
  end

  def check_unique_users
    @dupe_checksums.map do |dc|
      # Build hash table with user key (need unique users)
      user_sets = dc.group_by { |t| t[2] }.values.reject { |set| set.size < 2 }
      # Get the sets that were submitted later and only get the code
      user_sets.map { |set| set[1..].map { |t| t[0] } }.flatten
    end.flatten
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
    dupe_responses = Response.where(shortcode: dupe_codes).map(&:id)
    attachments = ActiveStorage::Attachment.where(record_id: dupe_responses)
    FileUtils.mkdir_p(TMP_DUPE_BACKUPS_PATH)
    attachments.each do |a|
      copy_attachment(a)
    end
  end

  def copy_attachment(attachment)
    File.open("#{TMP_DUPE_BACKUPS_PATH}/#{attachment.filename}", "w") do |f|
      attachment.download { |chunk| f.write(chunk) }
    end
  rescue StandardError => e
    Rails.logger.debug(e.message)
    ExceptionNotifier.notify_exception(e, data: {response: attachment.filename.to_s})
  end

  def destroy_duplicates!
    puts "Destroying #{dupe_codes}"
    ResponseDestroyer.new(scope: Response.where(shortcode: dupe_codes)).destroy!
  end

  def clean_up
    Response.dirty_dupe.each do |r|
      r.dirty_dupe = false
      r.save!
    end
  end
end
