class OperationJob < ApplicationJob
  queue_as :default

  rescue_from StandardError, with: :operation_raised_error

  before_perform :operation_started, if: :operation
  after_perform :operation_completed, if: :operation

  protected

  def operation
    # The `Operation` instance tracking this job is always passed as
    # the first argument to `perform`
    arguments.first
  end

  def operation_started
    operation.update_attribute(:job_started_at, Time.now)
  end

  def operation_succeeded(attachment = nil)
    operation.update_attribute(:attachment, attachment) if attachment.present?
  end

  def operation_failed(report)
    save_failure(report)
  end

  def operation_raised_error(exception)
    ExceptionNotifier.notify_exception(exception)
    save_failure(I18n.t("operation.server_error"))
  end

  def operation_completed
    operation.update_attribute(:job_completed_at, Time.now)
  end

  private

  def save_failure(msg)
    attributes = { job_failed_at: Time.now, job_error_report: msg }
    attributes[:job_completed_at] = Time.now unless operation.completed?
    operation.update_attributes(attributes)
  end
end
