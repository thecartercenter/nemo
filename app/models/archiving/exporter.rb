# frozen_string_literal: true

require "fileutils"

# Note: Documented in "Server Archiving" wiki page.
module Archiving
  # Outputs data to CSV ZIP bundle.
  class Exporter
    attr_accessor :relations, :options

    def initialize(relations, **options)
      self.relations = relations
      self.relations = [User.assigned_to(Mission.first)] if options[:debug]
      self.options = options
      self.options = {dont_implicitly_expand: [Assignment, UserGroup, UserGroupAssignment]} if options[:debug]
    end

    def export
      expander = RelationExpander.new(relations, dont_implicitly_expand: options[:dont_implicitly_expand])
      buffer = Zip::OutputStream.write_buffer do |out|
        expander.expanded.each do |klass, relations|
          col_names = klass.column_names - %w[standard_copy last_mission_id]
          relations.each_with_index do |relation, idx|
            relation = relation.select(col_names.join(", ")) unless col_names == klass.column_names
            relation.each do |entry|
              out.put_next_entry("#{klass.name.tr(':', '_')}-#{idx}-#{entry.id}.csv")
              relation.where(id: entry.id).copy_to { |line| out.write(line) }
            end
          end
        end
      end
      FileUtils.mkdir_p(export_dir)
      File.open(zipfile_path, "wb") { |f| f.write(buffer.string) }
    end

    private

    def export_dir
      @export_dir ||= Rails.root.join("tmp/archives")
    end

    def zipfile_path
      @zipfile_path ||= export_dir.join("#{Time.zone.now.to_fs(:filename_datetime)}.zip")
    end
  end
end
