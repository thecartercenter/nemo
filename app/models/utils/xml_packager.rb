# frozen_string_literal: true

require "sys/filesystem"
require "zip"
require "fileutils"

module Utils
  # Utility to support a bulk image download operation
  class XmlPackager < Packager
    TMP_DIR = "tmp/odk_xml"

    def download_scope
      responses = Response.accessible_by(@ability, :export)
      responses = apply_search_scope(responses, @search, @operation.mission) if @search.present?

      responses.joins("INNER JOIN active_storage_attachments ON
        active_storage_attachments.record_id = responses.id")
        .joins("INNER JOIN active_storage_blobs ON
        active_storage_blobs.id = active_storage_attachments.blob_id")
    end

    def download_and_zip_xml
      FileUtils.mkdir_p(Rails.root.join(TMP_DIR))
      filename = "#{@operation.mission.compact_name}-xml-responses-"\
        "#{Time.current.to_s(:filename_datetime)}.zip"
      zipfile_name = Rails.root.join(TMP_DIR, filename)
      zip(zipfile_name, download_scope)
    end

    def human_readable_xml(response)
      xml_string = response.odk_xml.download
      qings = response.form.questionings
      # replace qing id with human readable name
      qings.each do |q|
        human_readable = "<#{q.code} question='#{q.name}'>"
        xml_string.gsub!("<qing#{q.id}>", human_readable)
        xml_string.gsub!("</qing#{q.id}>", "</#{q.code}>")
      end
      xml_string
    end

    private

    def zip(zipfile_name, download_scope)
      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
        download_scope.each do |response|
          next unless response.odk_xml.present?
          zip_xml(zipfile, response)
        rescue Zip::EntryExistsError => e
          report_error(e)
          next
        end
      end
      zipfile_name
    end

    def zip_xml(zipfile, response)
      xml_filename = "nemo-response-#{response.shortcode}.xml"
      xml_filepath = Rails.root.join(TMP_DIR, xml_filename)
      File.write(xml_filepath, human_readable_xml(response))
      zip_entry = Utils::ZipEntry.new(xml_filepath, xml_filename)
      zipfile.add(zip_entry, xml_filepath)
    end

    def report_error(error)
      Sentry.add_breadcrumb(Sentry::Breadcrumb.new(
        message: "Mission: #{@operation.mission.compact_name}. Response ID: #{rid}"
      ))
      notify_admins(error)
    end
  end
end
