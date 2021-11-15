# frozen_string_literal: true

require "sys/filesystem"
require "zip"
require "fileutils"

module Utils
  # Parent packager class to support common packaging activities
  class Packager
    include ActiveModel::Model

    # Space we want to leave on disk in mib
    DISK_ALLOWANCE = 2048

    attr_accessor :ability, :search, :selected, :operation

    def initialize(attribs)
      attribs.each { |key, value| send("#{key}=", value) }
    end

    def space_on_disk?
      stat = Sys::Filesystem.stat("/")
      # need to leave space for images, zip file, and copy of zip file while attaching to operation
      space_left = bytes_to_mib(stat.block_size * stat.blocks_available) -
        bytes_to_mib(download_size * 2)
      space_left >= DISK_ALLOWANCE
    end

    def download_size
      @download_size ||= download_scope.sum("active_storage_blobs.byte_size")
    end

    def download_meta
      {space_on_disk: space_on_disk?, download_size: bytes_to_mb(download_size)}
    end

    private

    def apply_search_scope(responses, search, mission)
      ResponsesSearcher.new(relation: responses, query: search, scope: {mission: mission}).apply
    end

    def bytes_to_mib(bytes)
      bytes / 1024 / 1024
    end

    def bytes_to_mb(bytes)
      ((bytes / 1024.0 / 1024.0) * 1.049).round(2)
    end

    def notify_admins(error)
      Notifier.bug_tracker_warning(error).deliver_now
    end
  end
end
