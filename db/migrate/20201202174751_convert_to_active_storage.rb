# frozen_string_literal: true

# Find all existing Paperclip attachments and add ActiveStorage entries for them.
# From https://github.com/thoughtbot/paperclip/blob/master/MIGRATING.md
class ConvertToActiveStorage < ActiveRecord::Migration[6.0]
  require "open-uri"

  def up
    get_blob_id = "LASTVAL()"

    ActiveRecord::Base.connection.raw_connection.prepare("active_storage_blob_statement", <<-SQL)
      INSERT INTO active_storage_blobs (
        key, filename, content_type, metadata, byte_size, checksum, created_at
      ) VALUES ($1, $2, $3, '{}', $4, $5, $6)
    SQL

    ActiveRecord::Base.connection.raw_connection.prepare("active_storage_attachment_statement", <<-SQL)
      INSERT INTO active_storage_attachments (
        name, record_type, record_id, blob_id, created_at
      ) VALUES ($1, $2, $3, #{get_blob_id}, $4)
    SQL

    transaction do
      NEMO_ATTACHMENTS.each do |pair|
        relation, attachment_key = pair
        relation = relation.where.not("#{attachment_key}_file_size".to_sym => nil)

        total = relation.all.count
        puts "Converting #{total} #{relation.name.pluralize}..."

        relation.find_each.each_with_index do |instance, index|
          puts "Converting #{relation.name} #{attachment_key} #{instance.id} (#{index + 1} / #{total})"

          checksum = generate_checksum(instance.send(attachment_key))

          if checksum.nil?
            puts "  => File not found!"
            next
          end

          ActiveRecord::Base.connection.raw_connection.exec_prepared(
            "active_storage_blob_statement", [
              key(instance, attachment_key),
              instance.send("#{attachment_key}_file_name"),
              instance.send("#{attachment_key}_content_type"),
              instance.send("#{attachment_key}_file_size"),
              checksum,
              instance.updated_at.iso8601
            ]
          )

          ActiveRecord::Base.connection.raw_connection.exec_prepared(
            "active_storage_attachment_statement", [
              attachment_key,
              relation.name,
              instance.id,
              instance.updated_at.iso8601
            ]
          )
        end
      end
    end
  end

  def down
    # Don't bother deleting the new records
  end

  private

  NEMO_ATTACHMENTS = [
    [Operation, "attachment"],
    [SavedUpload, "file"],
    [Question, "media_prompt"],
    [Media::Object, "item"],
    [Response, "odk_xml"]
  ].freeze

  def key(_instance, _attachment)
    SecureRandom.uuid
    # Alternatively:
    # instance.send("#{attachment}_file_name")
  end

  # Note: This is super slow when running synchronously with cloud storage.
  # Parallelizing these downloads isn't compatible with exec_prepared above,
  # so the best solution is probably to copy all files locally before running this migration.
  def generate_checksum(attachment)
    if Rails.configuration.active_storage.service == :local
      path = attachment.path
      Digest::MD5.base64digest(File.read(path))
    else
      url = attachment.url
      data = Net::HTTP.get(URI(url))
      return nil if data.match?(%r{<Message>Access Denied</Message>})
      Digest::MD5.base64digest(data)
    end
  rescue Errno::ENOENT
    nil
  end
end
