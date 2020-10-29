# frozen_string_literal: true

require "fileutils"

# TODO: This class needs tests
module Cloning
  # Outputs data to CSV ZIP bundle.
  class Exporter
    attr_accessor :relations, :options

    def initialize(relations, **options)
      self.relations = relations
      self.options = options
    end

    def export
      expander = RelationExpander.new(relations, dont_implicitly_expand: options[:dont_implicitly_expand])
      buffer = Zip::OutputStream.write_buffer do |out|
        expander.expanded.each do |relation|
          # TODO: Improve this logic a bit, make it more structured and check table name
          col_names = relation.klass.column_names - %w[standard_copy last_mission_id]
          relation = relation.select(col_names.join(", ")) unless col_names == relation.klass.column_names
          out.put_next_entry("#{relation.klass.name.tr(':', '_')}.csv")
          relation.copy_to { |line| out.write(line) }
        end
      end
      FileUtils.mkdir_p(export_dir)
      File.open(zipfile_path, "wb") { |f| f.write(buffer.string) }
    end

    private

    def export_dir
      @export_dir ||= Rails.root.join("tmp/exports")
    end

    def zipfile_path
      @zipfile_path ||= export_dir.join("#{Time.zone.now.to_s(:filename_datetime)}.zip")
    end
  end
end
