# frozen_string_literal: true

require "fileutils"

# TODO: Document in "Server Archiving" wiki page.
module Archiving
  # Outputs data to CSV ZIP bundle.
  class Exporter
    attr_accessor :relations, :options

    # Hard-coded defaults generally shouldn't need to be overridden.
    def initialize(relations = nil, **options)
      self.relations = relations || [
        Mission.all,
        User.all,
        Assignment.all
      ]

      # Optional smaller set for debugging.
      m = Mission.first
      self.relations = relations || [
        Mission.where(id: m.id),
        User.assigned_to(m),
        Assignment.where(mission: m),
      ]

      self.options = {
        dont_implicitly_expand: [Setting, UserGroup, UserGroupAssignment]
      }.merge(options)
    end

    # TODO: export separately:
    #   responses (OData JSON and/or XML)
    #   formAttachments - hint/media prompt (file)
    #   responseAttachments - submission data (file)
    #   PLUS
    #   ability to interrupt & resume (or at least for uploading)
    def export
      expander = RelationExpander.new(relations, dont_implicitly_expand: options[:dont_implicitly_expand])
      buffer = Zip::OutputStream.write_buffer do |out|
        expander.expanded.each do |klass, relations|
          col_names = klass.column_names - %w[standard_copy last_mission_id]
          relations.each do |relation|
            relation = relation.select(col_names.join(", ")) unless col_names == klass.column_names
            relation.each do |entry|
              # Filename must be in the format `ClassName 123-456.csv` with a space followed by the ID of the item,
              # since this is used in the uploader script to process files.
              out.put_next_entry("#{klass.name.tr(':', '_')} #{entry.id}.csv")
              # Pick out this single entry (but keep the ActiveRecord relation to be able to use `copy_to`)
              # and save each to disk.
              relation.where(id: entry.id).copy_to { |line| out.write(line) }
            end
          end
        end

        Form.all.each do |form|
          out.put_next_entry("Form #{form.id}.xlsx")
          out.write(Forms::Export.new(form).to_xls)
        end

        Response.all.each do |response|
          out.put_next_entry("Response #{response.id}.json")
          out.write(response.cached_json.to_json) # This will be the string "null" if it's not yet cached.
          # TODO: track errors if dirty.
        end
      end
      FileUtils.mkdir_p(export_dir)
      File.open(zipfile_path, "wb") { |f| f.write(buffer.string) }

      Rails.logger.info("Exported #{zipfile_path}")
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
