# This class only maintains the state of an operation and should
# not be subclassed directly.  To implement a new type of operation,
# subclass `OperationJob` and implement the `perfom(operation, *args)`
# method.
class Operation < ApplicationRecord
  include MissionBased
  belongs_to :creator, class_name: 'User'

  has_attached_file :attachment

  def name
    "##{id}"
  end

  def begin!(*args)
    save! unless persisted?

    # enqueue the job to be performed async
    job = job_class.constantize.perform_later(self, *args)

    update_attributes(job_id: job.job_id, provider_job_id: job.provider_job_id)
  end

  def pending?
    job_started_at.nil?
  end

  def failed?
    job_failed_at.present?
  end

  def completed?
    job_completed_at.present?
  end

  def status
    if pending?
      :pending
    elsif failed?
      :failed
    elsif completed?
      :completed
    else
      :running
    end
  end
end
