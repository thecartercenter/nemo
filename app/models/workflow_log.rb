# frozen_string_literal: true

# == Schema Information
#
# Table name: workflow_logs
#
#  id                  :uuid             not null, primary key
#  workflow_instance_id :uuid            not null
#  event_type          :string(255)      not null
#  message             :text             not null
#  user_id             :uuid
#  data                :jsonb
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_workflow_logs_on_workflow_instance_id  (workflow_instance_id)
#  index_workflow_logs_on_event_type           (event_type)
#  index_workflow_logs_on_user_id              (user_id)
#

class WorkflowLog < ApplicationRecord
  belongs_to :workflow_instance
  belongs_to :user, optional: true

  validates :event_type, presence: true
  validates :message, presence: true

  scope :by_event_type, ->(type) { where(event_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  EVENT_TYPES = %w[
    created
    started
    step_advance
    approval
    rejection
    cancellation
    completion
    failure
    notification
    action
  ].freeze

  def formatted_timestamp
    created_at.strftime('%Y-%m-%d %H:%M:%S')
  end

  def user_name
    user&.name || 'System'
  end

  def summary
    {
      id: id,
      event_type: event_type,
      message: message,
      user: user_name,
      timestamp: formatted_timestamp,
      data: data
    }
  end
end