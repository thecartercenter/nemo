# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: operations
#
#  id                                                :uuid             not null, primary key
#  attachment_content_type                           :string
#  attachment_download_name                          :string
#  attachment_file_name                              :string
#  attachment_file_size                              :integer
#  attachment_updated_at                             :datetime
#  details                                           :string(255)      not null
#  job_class                                         :string(255)      not null
#  job_completed_at                                  :datetime
#  job_error_report                                  :text
#  job_failed_at                                     :datetime
#  job_started_at                                    :datetime
#  notes                                             :string(255)
#  unread                                            :boolean          default(TRUE), not null
#  url                                               :string
#  created_at                                        :datetime         not null
#  updated_at                                        :datetime         not null
#  creator_id                                        :uuid
#  job_id                                            :string(255)
#  mission_id(Operations are possible in admin mode) :uuid
#  provider_job_id                                   :string(255)
#
# Indexes
#
#  index_operations_on_created_at  (created_at)
#  index_operations_on_creator_id  (creator_id)
#  index_operations_on_mission_id  (mission_id)
#
# Foreign Keys
#
#  fk_rails_...                (mission_id => missions.id)
#  operations_creator_id_fkey  (creator_id => users.id) ON DELETE => restrict ON UPDATE => restrict
#
# rubocop:enable Layout/LineLength

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

  # TODO: Send via rails_blob_path(attachment, disposition: "attachment")
  has_one_attached :attachment

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
    # We need to save before passing to perform_later b/c perform_later will need our ID.
    # For this reason, the job_id col can't have a null constraint.
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
