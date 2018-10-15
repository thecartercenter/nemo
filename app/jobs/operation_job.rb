# frozen_string_literal: true

# An operation job is an ActiveJob with an associated `Operation`
# context to manage its state.  By convention, the job's `Operation` is
# passed as the first argument to the `perform` method.
class OperationJob < ApplicationJob
  queue_as :default

  rescue_from StandardError, with: :operation_raised_error

  # These callbacks are conditional on the operation record being present
  # in the database.  While unlikely, it's possible that the job was pending
  # in the queue and, meanwhile, the operation record was deleted.
  before_perform :operation_started, if: :operation
  before_perform :load_settings, if: :operation
  after_perform :operation_completed, if: :operation

  delegate :mission, to: :operation

  protected

  def operation
    # The `Operation` instance tracking this job is always passed as
    # the first argument to `perform`
    arguments.first
  end

  def operation_started
    operation.update!(job_started_at: Time.current)
  end

  def load_settings
    # load the mission's settings into configatron
    # if mission is nil, the admin mode settings will be loaded
    Setting.load_for_mission(mission)
  end

  def operation_succeeded(attributes = nil)
    operation.update!(attributes) if attributes.present?
  end

  def operation_failed(report)
    save_failure(report)
  end

  def operation_raised_error(exception)
    ExceptionNotifier.notify_exception(exception)
    save_failure(I18n.t("operation.errors.server_error"))
  end

  def operation_completed
    operation.update!(job_completed_at: Time.current)
  end

  protected

  def save_failure(msg)
    attributes = {job_failed_at: Time.current, job_error_report: msg}
    attributes[:job_completed_at] = Time.current unless operation.completed?
    operation.update!(attributes)
  end
end
