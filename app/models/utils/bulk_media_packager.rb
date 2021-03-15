# frozen_string_literal: true

require "sys/filesystem"
require "zip"
require "fileutils"

module Utils
  # Utility to support a bulk image download operation
  class BulkMediaPackager
    include ActiveModel::Model
    # Space we want to leave on disk in mb in base 2
    DISK_ALLOWANCE = 2048
    TMP_DIR = "tmp/bulk_images"

    attr_accessor :ability, :search, :operation

    def media_objects_scope
      responses = Response.accessible_by(@ability, :export)
      responses = apply_search_scope(responses, @search, @operation.mission) if @search.present?
      responses.joins(:answers)
        .joins("INNER JOIN media_objects ON media_objects.answer_id = answers.id")
        .joins("INNER JOIN active_storage_attachments ON
          active_storage_attachments.record_id = media_objects.id")
        .joins("INNER JOIN active_storage_blobs ON
          active_storage_blobs.id = active_storage_attachments.blob_id")
    end

    def calculate_media_size
      media_objects_scope.sum("active_storage_blobs.byte_size")
    end

    def space_on_disk?
      stat = Sys::Filesystem.stat("/")
      space_left = bytes_to_mb(stat.block_size * stat.blocks_available) -
        bytes_to_mb(calculate_media_size)
      space_left >= DISK_ALLOWANCE
    end

    def download_and_zip_images
      Dir.mkdir(Rails.root.join(TMP_DIR)) unless
        File.exist?(Rails.root.join(TMP_DIR))

      media_ids = media_objects_scope.pluck("media_objects.id")

      zipfile_name = Rails.root.join(TMP_DIR,
        "bulk_images_archive_#{Time.zone.now.strftime('%Y-%m-%d_%H-%M-%S')}.zip")

      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
        media_ids.each do |media_id|
          attachment = ::Media::Object.find(media_id).item
          attachment.open do |file|
            filename = File.basename(file.path)
            new_path = Rails.root.join(TMP_DIR, filename)
            FileUtils.mv(file.path, new_path)
            zip_entry = Utils::ZipEntry.new(new_path, filename)
            zipfile.add(zip_entry, new_path)
          end
        end
      end
      zipfile_name
    end

    private

    def apply_search_scope(responses, search, mission)
      ResponsesSearcher.new(relation: responses, query: search, scope: {mission: mission}).apply
    end

    def bytes_to_mb(bytes)
      bytes / 1024 / 1024
    end
  end
end
