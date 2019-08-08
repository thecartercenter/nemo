# frozen_string_literal: true

# Job for importing tabular data like users and option sets.
class TabularImportOperationJob < OperationJob
  def perform(_operation, name: nil, saved_upload_id:, import_class:)
    saved_upload = SavedTabularUpload.find(saved_upload_id)
    import = import_class.constantize.new(
      mission_id: mission&.id,
      name: name,
      file: open_file(saved_upload.file)
    )
    import.run
    operation_failed(format_error_report(import.run_errors)) unless import.succeeded?
  end

  private

  # turn the import errors into a report in markdown format
  def format_error_report(errors)
    return if errors.empty?
    errors.map { |error| "* #{error}" }.join("\n")
  end

  def open_file(file)
    if file.options[:storage] == "fog"
      # Preserve the file extension (Roo, for example, requires this in order to parse)
      pathname = Pathname.new(file.path)
      tmp = Tempfile.new(["tabular_import", pathname.basename.to_s])
      tmp.binmode
      URI.parse(file.expiring_url).open { |io| tmp.write(io.read) }
      tmp.rewind
      tmp
    else
      file
    end
  end
end
