# frozen_string_literal: true

require "sys/filesystem"
require "zip"
require "fileutils"

module Utils
  # Extends ::Zip::Entry to include clean up method,
  # which is called automatically by the library.
  class ZipEntry < ::Zip::Entry
    def clean_up
      FileUtils.rm(@zipfile)
    end
  end
end
