# frozen_string_literal: true

require "sys/filesystem"
require "zip"
require "fileutils"

module Utils
  # Utility to support a bulk image download operation
  class BulkMediaPackager
    include ActiveModel::Model
    # Space we want to leave on disk in mib
    DISK_ALLOWANCE = 2048
    TMP_DIR = "tmp/bulk_media"

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
      # need to leave space for images, zip file, and copy of zip file while attaching to operation
      space_left = bytes_to_mib(stat.block_size * stat.blocks_available) -
        bytes_to_mib(calculate_media_size * 2)
      space_left >= DISK_ALLOWANCE
    end

    def download_and_zip_images
      FileUtils.mkdir_p(Rails.root.join(TMP_DIR))

      media_ids = media_objects_scope.pluck("media_objects.id")

      filename = "#{@operation.mission.compact_name}-media-#{Time.current.to_s(:filename_datetime)}.zip"
      zipfile_name = Rails.root.join(TMP_DIR, filename)
      zip(zipfile_name, media_ids)
    end

    private

    def zip(zipfile_name, media_ids)
      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
        media_ids.each do |media_id|
          zip_media(::Media::Object.find(media_id).item, zipfile)
        rescue Zip::EntryExistsError => e
          notify_admins(e)
          next
        end
      end
      zipfile_name
    end

    def notify_admins(error)
      Notifier.bug_tracker_warning(error).deliver_now
    end

    def zip_media(attachment, zipfile)
      attachment.open do |file|
        filename = attachment.filename.to_s
        new_path = Rails.root.join(TMP_DIR, filename)
        FileUtils.mv(file.path, new_path)
        zip_entry = Utils::ZipEntry.new(new_path, filename)
        zipfile.add(zip_entry, new_path)
      end
    end

    def apply_search_scope(responses, search, mission)
      ResponsesSearcher.new(relation: responses, query: search, scope: {mission: mission}).apply
    end

    def bytes_to_mib(bytes)
      bytes / 1024 / 1024
    end
  end
end
