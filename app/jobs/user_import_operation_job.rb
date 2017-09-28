class UserImportOperationJob < OperationJob
  def perform(operation, current_mission, path)
    # load the current mission's settings into configatron
    Setting.load_for_mission(current_mission)

    batch = UserBatch.new(file: File.new(path))
    succeeded = batch.create_users(current_mission)

    unless succeeded
      operation_failed(format_error_report(batch.errors))
    end
  end

  private

    # turn the ActiveModel::Errors into a report in markdown format
    def format_error_report(errors)
      return if errors.empty?

      errors.values.flatten.map { |error| "* #{error}" }.join("\n")
    end
end
