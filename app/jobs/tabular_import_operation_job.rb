# frozen_string_literal: true

# Job for importing tabular data like users and option sets.
class TabularImportOperationJob < OperationJob
  def perform(_operation, saved_upload_id:, import_class:, name: nil)
    saved_upload = SavedTabularUpload.find(saved_upload_id)
    import = import_class.constantize.new(
      mission_id: mission&.id,
      name: name,
      file: saved_upload.file.download
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
end
