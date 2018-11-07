# frozen_string_literal: true

# Job for importing tabular data like users and option sets.
class TabularImportOperationJob < OperationJob
  def perform(_operation, name: nil, saved_upload_id:, import_class:)
    if import_class
      saved_upload = SavedUpload.find(saved_upload_id)
      import = import_class.constantize.new(mission_id: mission.try(:id), name: name, file: saved_upload.file)
      succeeded = import.run(mission)
    end

    operation_failed(format_error_report(import.try(:errors))) unless succeeded
  end

  private

  # turn the ActiveModel::Errors into a report in markdown format
  def format_error_report(errors)
    return if errors.empty?

    errors.values.flatten.map { |error| "* #{error}" }.join("\n")
  end
end
