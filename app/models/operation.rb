class Operation < ApplicationRecord
  belongs_to :creator, class_name: 'User'

  validates :job_class, presence: true
  validates :creator, presence: true
  validates :description, presence: true

  def name
    "##{id}"
  end

  def begin!(*args)
    save! unless persisted?

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
