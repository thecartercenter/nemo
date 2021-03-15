# frozen_string_literal: true

require "sys/filesystem"
require "zip"
require "fileutils"

module Utils
  class ZipEntry < ::Zip::Entry

    def clean_up
      FileUtils.rm @zipfile
    end

  end
end
