class OperationJob < ApplicationJob
  queue_as :default

  rescue_from StandardError, with: :operation_failed

  before_perform { |job| job.operation_started }

  after_perform { |job| job.operation_completed }

  protected

    def operation
      arguments.first.tap do |operation|
        raise ArgumentError unless operation.is_a?(Operation)
      end
    end

    def operation_started
      operation.update_attribute(:job_started_at, Time.now)
    end

    def operation_succeeded(outcome_url=nil)
      operation.update_attribute(:job_outcome_url, outcome_url) if outcome_url.present?
    end

    def operation_failed(exception_or_report=nil)
      error_report =
        case exception_or_report
        when StandardError
          exception_or_report.message
        else
          exception_or_report.to_s
        end

      attributes = {
        job_failed_at: Time.now,
        job_error_report: error_report
      }

      attributes[:job_completed_at] = Time.now unless operation.completed?

      operation.update_attributes(attributes)
    end

    def operation_completed
      operation.update_attribute(:job_completed_at, Time.now)
    end
end
