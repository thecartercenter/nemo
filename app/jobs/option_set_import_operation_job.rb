class OptionSetImportOperationJob < OperationJob
  def perform(operation, current_mission, name, path)
    # load the current mission's settings into configatron
    Setting.load_for_mission(current_mission)

    import = OptionSetImport.new(mission_id: current_mission.try(:id), name: name, file: path)
    succeeded = import.create_option_set

    unless succeeded
      operation_failed(format_error_report(import.errors))
    end
  end

  private

    # turn the ActiveModel::Errors into a report in markdown format
    def format_error_report(errors)
      return if errors.empty?

      errors.values.flatten.map { |error| "* #{error}" }.join("\n")
    end
end
