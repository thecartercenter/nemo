class TabularImportOperationJob < OperationJob
  def perform(operation, current_mission, name, path, import_class)
    # load the current mission's settings into configatron
    Setting.load_for_mission(current_mission)

    if import_class
      import = import_class.constantize.new(mission_id: current_mission.try(:id), name: name, file: path)
      succeeded = import.run(current_mission)
    end

    operation_failed(format_error_report(import.try(:errors))) unless succeeded
  ensure
    File.delete(path) rescue nil
  end

  private

  # turn the ActiveModel::Errors into a report in markdown format
  def format_error_report(errors)
    return if errors.empty?

    errors.values.flatten.map { |error| "* #{error}" }.join("\n")
  end
end
