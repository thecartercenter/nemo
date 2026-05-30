# frozen_string_literal: true

require "fileutils"

# TODO: Document in "Server Archiving" wiki page.
# rubocop:disable Rails/Output
module Archiving
  # Outputs data to CSV ZIP bundle.
  class Exporter
    attr_accessor :relations, :dont_implicitly_expand

    # Optionally accepts a list of relations to export and ignore.
    # Hard-coded defaults generally shouldn't need to be overridden for archival.
    def initialize(relations: nil, dont_implicitly_expand: nil)
      self.relations = relations || [
        Mission.all,
        User.all,
        Assignment.all,
      ]

      self.dont_implicitly_expand = dont_implicitly_expand || [
        Setting,
        UserGroup,
        UserGroupAssignment,
      ]
    end

    # Verbose will log SQL queries.
    # Skip is an array of steps to skip ("relations", "forms", "hints", "responses", "attachments").
    def export(verbose: false, skip: [])
      skip = skip.map(&:to_s)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      begin
        if verbose
          perform_export(skip: skip)
        else
          silence_verbose_logs { perform_export(skip: skip) }
        end
      ensure
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        puts "Export took #{elapsed.round(2)}s"
      end
    end

    def perform_export(skip: [])
      warnings = []

      FileUtils.mkdir_p(export_dir)
      Zip::OutputStream.open(zipfile_path) do |out|
        self.relations = [] if skip.include?("relations")
        puts "Exporting relations: #{relations.map(&:klass).join(', ')}..."
        expander = RelationExpander.new(relations, dont_implicitly_expand: dont_implicitly_expand)
        expander.expanded.each do |klass, relations|
          puts "  Exporting #{klass.count} #{klass.name.pluralize}..."
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

        items = skip.include?("forms") ? Form.none : Form.with_attached_odk_xml
        total_count = items.count
        curr_count = 0
        items.find_each do |form|
          puts "Exporting form #{curr_count += 1}/#{total_count}: #{form.name}..."

          # XLSX version of the form
          out.put_next_entry("Form #{form.id}.xlsx")
          out.write(Forms::Export.new(form).to_xls)

          # Equivalent ODK XML version of the form
          out.put_next_entry("Form #{form.id}.xml")
          out.write(form.odk_xml.download)
        end

        items = skip.include?("hints") ? Question.none : Question.joins(:media_prompt_attachment).with_attached_media_prompt
        total_count = items.count
        curr_count = 0
        items.find_each do |question|
          puts "Exporting media_prompt #{curr_count += 1}/#{total_count}: #{question.code}..."
          mp = question.media_prompt
          # Convert the filename from e.g. "123_media_prompt.jpg" to "MediaPrompt 123.jpg"
          out.put_next_entry("MediaPrompt #{question.id}.#{mp.filename.extension}")
          out.write(mp.download)
        end

        items = skip.include?("responses") ? Response.none : Response.all
        total_count = items.count
        curr_count = 0
        items.find_each do |response|
          # Responses to unpublished forms are generally not cached, and/or server jobs may be behind.
          if response.dirty_json?
            puts "Caching response #{response.shortcode}..."
            CacheODataJob.cache_response(response)
          end

          puts "Exporting response #{curr_count += 1}/#{total_count}: #{response.shortcode}..."
          out.put_next_entry("Response #{response.id}.json")
          out.write(response.cached_json.to_json) # This will be the string "null" if it's not yet cached.
          warn(warnings, "Response #{response.id} was dirty") if response.dirty_json
        end

        items = skip.include?("attachments") ? Media::Object.none : Media::Object.joins(:item_attachment).with_attached_item
        total_count = items.count
        curr_count = 0
        items.find_each do |obj|
          attachment = obj.item
          puts "Exporting response attachment #{curr_count += 1}/#{total_count}: #{attachment.filename}..."

          response_id = obj.answer.response_id
          code = attachment.filename.base.split("-").last

          begin
            data = attachment.download
            # Convert the filename from e.g. "nemo-foo-bar-baz-ImageQ1.jpg" to "ResponseAttachment 123 ImageQ1.jpg"
            # Where foo-bar-baz represents [mission_code]-[form_code]-[response_code] and 123 is the response ID.
            out.put_next_entry("ResponseAttachment #{response_id} #{code}.#{attachment.filename.extension}")
            out.write(data)
          rescue ActiveStorage::FileNotFoundError => e
            warn(warnings, "ResponseAttachment #{response_id} #{code} not found: #{e.message}")
          end
        end
      end

      puts
      Rails.logger.warn("Warnings:\n#{warnings.join("\n")}\n") unless warnings.empty?
      puts "Exported #{zipfile_path}"
      puts "Encountered #{warnings.count} warnings."
    end

    private

    # Log now, but also save them all for the end since it will likely get lost.
    def warn(warnings, msg)
      warnings.push(msg)
      Rails.logger.warn(msg)
    end

    def export_dir
      @export_dir ||= Rails.root.join("tmp/archives")
    end

    def zipfile_path
      @zipfile_path ||= export_dir.join("#{Time.zone.now.to_fs(:filename_datetime)}.zip")
    end

    def silence_verbose_logs
      # We could simply `Rails.logger.silence` but that would hide warnings too.
      loggers = [
        ActiveRecord::Base.logger,
      ].compact.uniq

      old_levels = loggers.index_with(&:level)
      loggers.each { |logger| logger.level = Logger::WARN }

      yield
    ensure
      old_levels.each { |logger, level| logger.level = level }
    end
  end
end
# rubocop:enable Rails/Output
