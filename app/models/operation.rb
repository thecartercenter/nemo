# frozen_string_literal: true

# An operation represents work to be performed in the background.
# This model stores the state of the background job but does not
# actually perform any of the work itself and should not be subclassed
# when creating a new type of operation.
# To implement a new type of operation, subclass `OperationJob` and
# implement the `perfom(operation, *args)` method.
class Operation < ApplicationRecord
  include MissionBased

  # This is an ephemeral attribute that gets passed to the job when it is enqueued.
  # Anything stored in here should be small and serializable.
  attr_accessor :job_params

  belongs_to :creator, class_name: "User"

  has_attached_file :attachment
  do_not_validate_attachment_file_type :attachment

  def name
    "##{id}"
  end

  # Returns an underscored version of the job class name minus the OperationJob suffix.
  def kind
    job_class.underscore.sub(/_operation_job$/, "")
  end

  # Enqueues the appropriate OperationJob to be run later.
  # Passes self and the contents of the job_params attrib (with double splat) to the perform_later method.
  # Since job_params is ephemeral, enqueue should be called right after the operation is created, not
  # on an operation object retrieved from the DB.
  def enqueue
    save! unless persisted?
    job = job_class.constantize.perform_later(self, **job_params)
    update!(job_id: job.job_id, provider_job_id: job.provider_job_id)
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
