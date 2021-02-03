# frozen_string_literal: true

class CopyActiveStorageFromPaperclipCloud < ActiveRecord::Migration[6.0]
  def up
    if Rails.configuration.active_storage.service == :local
      # Nothing to do, already copied in the previous migration.
      puts "Using LOCAL storage."
    else
      puts "Using CLOUD storage."
      copy_all_s3
    end
  end
end

NEMO_ATTACHMENTS = [
  [Operation, "attachment"],
  [SavedUpload, "file"],
  [Question, "media_prompt"],
  [Media::Object, "item"],
  [Response, "odk_xml"]
].freeze

# Expectation: ActiveStorage syntax is ALREADY migrated
# (e.g. has_one_attached, NOT has_attached_file).
#
# By default, Paperclip looks like this:
# public/system/users/avatars/000/000/004/original/the-mystery-of-life.png
#
# And ActiveStorage is all in the root directory with obfuscated filenames (for cloud storage).
#
# From https://github.com/thoughtbot/paperclip/blob/master/MIGRATING.md
def copy_all_s3
  NEMO_ATTACHMENTS.each do |pair|
    relation, title = pair
    relation = relation.where.not("#{title}_file_size".to_sym => nil)
    total = relation.count

    puts "Copying #{total} #{relation.name} #{title.pluralize}..."
    num_threads = (ENV["NUM_THREADS"].presence || 30).to_i
    Parallel.each_with_index(relation.each, in_threads: num_threads) do |record, index|
      copy_s3_item(record, title, index, total)
    end
  end
end

# Download a Paperclip item from S3 and re-attach it using ActiveStorage.
def copy_s3_item(record, title, index, total)
  filename = record.send("#{title}_file_name")
  url = record.send("#{title}_legacy_url")
  # For debugging: .presence || "https://nemo-stg.s3.amazonaws.com/uploads"

  if url.nil?
    puts "  => Nil URL, probably an old missing file for #{filename} (id #{record.id})."
    return
  end

  # Hack to avoid double-saving files when running this multiple times in a row
  # (no fast way to determine if an attachment is stored in ActiveStorage vs. Paperclip location).
  if ENV["SKIP_MINUTES_AGO"].present?
    attachment = record.send(title).attachment
    if attachment && attachment.created_at > ENV["SKIP_MINUTES_AGO"].to_f.minutes.ago
      puts "Skipping existing #{filename}"
      return
    end
  end

  puts "Copying #{filename}... (#{index + 1} / #{total})"
  puts "  at #{url}" if ENV["VERBOSE"]
  record.send(title).attach(io: URI.parse(url).open, filename: filename,
                            content_type: record.send("#{title}_content_type"))
rescue StandardError => e
  raise e unless e.message == "403 Forbidden"
  puts "  => File no longer exists (or server does not have access) for #{filename} (id #{record.id})."
end
