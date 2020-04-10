# frozen_string_literal: true

# TODO: This class needs tests
module Cloning
  # Imports from CSV ZIP bundle.
  class Importer
    attr_accessor :zip_file

    def initialize(zip_file)
      self.zip_file = zip_file
    end

    def import
      ApplicationRecord.transaction do
        # Defer constraints so that constraints are not checked until all data is loaded.
        SqlRunner.instance.run("SET CONSTRAINTS ALL DEFERRED")
        Zip::InputStream.open(zip_file) do |io|
          while (entry = io.get_next_entry)
            klass = entry.name.sub(/.csv$/, "").tr("_", ":").constantize
            klass.copy_from(io)
          end
        end
      end
    end
  end
end
