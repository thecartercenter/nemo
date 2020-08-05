# frozen_string_literal: true

# User-facing operation to display background Job progress.
class CacheODataOperationJob < OperationJob
  # Noop that finishes immediately.
  def perform(_operation)
  end

  # Override super so that it won't get marked "done" automatically.
  def operation_completed
  end
end
