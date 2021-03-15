# frozen_string_literal: true

require "sys/filesystem"
require "zip"
require "fileutils"

module Utils
  # Extends ::Zip::Entry to include clean up method
  class ZipEntry < ::Zip::Entry
    def clean_up
      FileUtils.rm(@zipfile)
    end
  end
end
