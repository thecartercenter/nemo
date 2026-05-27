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
        Assignment.all,
      ]

      self.options = {
        dont_implicitly_expand: [Setting, UserGroup, UserGroupAssignment]
      }.merge(options)
    end

    def export
      warnings = []

      FileUtils.mkdir_p(export_dir)
      Zip::OutputStream.open(zipfile_path) do |out|
        expander = RelationExpander.new(relations, dont_implicitly_expand: options[:dont_implicitly_expand])
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

        Form.with_attached_odk_xml.find_each do |form|
          # XLSX version of the form
          out.put_next_entry("Form #{form.id}.xlsx")
          out.write(Forms::Export.new(form).to_xls)

          # Equivalent ODK XML version of the form
          out.put_next_entry("Form #{form.id}.xml")
          out.write(form.odk_xml.download)
        end

        Question.joins(:media_prompt_attachment).with_attached_media_prompt.find_each do |question|
          mp = question.media_prompt
          # Convert the filename from e.g. "123_media_prompt.jpg" to "MediaPrompt 123.jpg"
          out.put_next_entry("MediaPrompt #{question.id}.#{mp.filename.extension}")
          out.write(mp.download)
        end

        Response.find_each do |response|
          out.put_next_entry("Response #{response.id}.json")
          out.write(response.cached_json.to_json) # This will be the string "null" if it's not yet cached.
          warnings.push("Response #{response.id} was dirty") if response.dirty_json
        end

        Media::Object.joins(:item_attachment).with_attached_item.find_each do |obj|
          attachment = obj.item
          response_id = obj.answer.response_id
          code = attachment.filename.base.split("-").last
          # Convert the filename from e.g. "nemo-foo-bar-baz-ImageQ1.jpg" to "ResponseAttachment 123 ImageQ1.jpg"
          # Where foo-bar-baz represents [mission_code]-[form_code]-[response_code] and 123 is the response ID.
          out.put_next_entry("ResponseAttachment #{response_id} #{code}.#{attachment.filename.extension}")
          out.write(attachment.download)
        end
      end

      Rails.logger.warn("Warnings:\n#{warnings.join("\n")}\n")
      Rails.logger.info("Exported #{zipfile_path}")
      Rails.logger.info("Encountered #{warnings.count} warnings.")
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
