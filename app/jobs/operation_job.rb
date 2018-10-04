class OperationJob < ApplicationJob
  queue_as :default

  rescue_from StandardError, with: :operation_raised_error

  before_perform :operation_started, if: :operation
  before_perform :load_settings, if: :operation
  after_perform :operation_completed, if: :operation

  protected

  def operation
    # The `Operation` instance tracking this job is always passed as
    # the first argument to `perform`
    arguments.first
  end

  def mission
    # The `Mission` instance is currently passed as the second arg
    # to all `OperationJob`s.
    # TODO: once an operation is associated with a mission this should
    # be changed to `operation.mission` and operation job argument lists
    # should be updated to omit the mission
    arguments.second
  end

  def operation_started
    operation.update_attribute(:job_started_at, Time.now)
  end

  def load_settings
    # load the mission's settings into configatron
    Setting.load_for_mission(mission)
  end

  def operation_succeeded(attributes = nil)
    operation.update_attributes(attributes) if attributes.present?
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
