# frozen_string_literal: true

# An operation job is an ActiveJob with an associated `Operation`
# context to manage its state.  By convention, the job's `Operation` is
# passed as the first argument to the `perform` method.
class OperationJob < ApplicationJob
  queue_as :default

  rescue_from StandardError, with: :operation_raised_error

  before_perform :load_timezone_from_mission
  before_perform :mark_operation_started
  after_perform :mark_operation_completed

  delegate :mission, to: :operation

  # The `Operation` instance tracking this job is always passed as
  # the first argument to `perform`. There is at least one case (CacheODataOperationJob) in which
  # no operation is passed. This should probably be refactored somehow.
  def operation
    arguments.first
  end

  def save_attachment(attachment, attachment_download_name)
    operation.attachment.attach(io: attachment, filename: attachment_download_name)
  end

  def operation_failed(report)
    save_failure(report)
  end

  # Handles unexpected errors. Expected errors should be handled explicitly in subclasses
  # and displayed nicely. Sends an exception notification email in production/dev mode,
  # Re-raises in test mode so we can see the backtrace and be aware something is failing weirdly.
  def operation_raised_error(exception)
    save_failure(I18n.t("operation.errors.server_error"))
    ExceptionNotifier.notify_exception(exception)
    raise exception if Rails.env.test?
  end

  private

  def mission_config
    Setting.for_mission(mission)
  end

  def load_timezone_from_mission
    Time.zone = mission_config.timezone
  end

  def mark_operation_started
    operation.update!(job_started_at: Time.current)
  end

  def mark_operation_completed
    operation.update!(job_completed_at: Time.current)
  end

  def save_failure(msg)
    return if operation.nil?
    attributes = {job_failed_at: Time.current, job_error_report: msg}
    attributes[:job_completed_at] = Time.current unless operation.completed?
    operation.update!(attributes)
  end
end
