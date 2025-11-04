# frozen_string_literal: true

# == Schema Information
#
# Table name: workflow_instances
#
#  id                  :uuid             not null, primary key
#  workflow_id         :uuid             not null
#  trigger_object_type :string(255)      not null
#  trigger_object_id   :uuid             not null
#  trigger_user_id     :uuid
#  status              :string(255)      default('pending'), not null
#  current_step        :integer          default(0), not null
#  started_at          :datetime
#  completed_at        :datetime
#  cancelled_at        :datetime
#  cancellation_reason :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_workflow_instances_on_workflow_id           (workflow_id)
#  index_workflow_instances_on_trigger_object        (trigger_object_type,trigger_object_id)
#  index_workflow_instances_on_trigger_user_id       (trigger_user_id)
#  index_workflow_instances_on_status                (status)
#

class WorkflowInstance < ApplicationRecord
  belongs_to :workflow
  belongs_to :trigger_object, polymorphic: true
  belongs_to :trigger_user, class_name: 'User', optional: true
  has_many :approval_requests, dependent: :destroy
  has_many :workflow_logs, dependent: :destroy

  validates :status, inclusion: { in: %w[pending in_progress completed cancelled failed] }
  validates :current_step, numericality: { greater_than_or_equal_to: 0 }

  scope :pending, -> { where(status: 'pending') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :failed, -> { where(status: 'failed') }
  scope :active, -> { where(status: %w[pending in_progress]) }

  def completed?
    status == 'completed'
  end

  def cancelled?
    status == 'cancelled'
  end

  def failed?
    status == 'failed'
  end

  def active?
    %w[pending in_progress].include?(status)
  end

  def progress_percentage
    total_steps = workflow.workflow_steps.count
    return 0 if total_steps.zero?
    
    (current_step.to_f / total_steps * 100).round(2)
  end

  def duration
    return nil unless started_at
    
    end_time = completed_at || cancelled_at || Time.current
    end_time - started_at
  end

  def current_step_object
    workflow.workflow_steps.find_by(step_number: current_step)
  end

  def next_step_object
    workflow.workflow_steps.find_by(step_number: current_step + 1)
  end

  def log_event(event_type, message, user = nil, data = {})
    workflow_logs.create!(
      event_type: event_type,
      message: message,
      user: user,
      data: data
    )
  end

  def can_be_cancelled_by?(user)
    return false unless active?
    return true if user.admin?
    return true if trigger_user == user
    return true if workflow.user == user
    
    # Check if user has approval permissions
    approval_requests.where(approver: user, status: 'pending').exists?
  end

  def can_be_approved_by?(user)
    return false unless active?
    return true if user.admin?
    
    approval_requests.where(approver: user, status: 'pending').exists?
  end

  def approve!(user, comments = nil)
    return false unless can_be_approved_by?(user)
    
    approval_request = approval_requests.find_by(approver: user, status: 'pending')
    return false unless approval_request
    
    approval_request.update!(
      status: 'approved',
      approved_at: Time.current,
      comments: comments
    )
    
    log_event('approval', "Approved by #{user.name}", user, { comments: comments })
    
    # Check if all approvals are received
    check_approval_completion
    
    true
  end

  def reject!(user, reason = nil)
    return false unless can_be_approved_by?(user)
    
    approval_request = approval_requests.find_by(approver: user, status: 'pending')
    return false unless approval_request
    
    approval_request.update!(
      status: 'rejected',
      rejected_at: Time.current,
      comments: reason
    )
    
    log_event('rejection', "Rejected by #{user.name}: #{reason}", user)
    
    # Cancel the workflow
    workflow.cancel_workflow(self, "Rejected by #{user.name}: #{reason}")
    
    true
  end

  def cancel!(user, reason = nil)
    return false unless can_be_cancelled_by?(user)
    
    workflow.cancel_workflow(self, reason)
    log_event('cancellation', "Cancelled by #{user.name}: #{reason}", user)
    
    true
  end

  def advance_to_next_step!
    return false unless active?
    
    workflow.next_step(self)
    log_event('step_advance', "Advanced to step #{current_step}")
    
    true
  end

  def summary
    {
      id: id,
      workflow_name: workflow.name,
      status: status,
      progress: progress_percentage,
      current_step: current_step,
      total_steps: workflow.workflow_steps.count,
      started_at: started_at,
      completed_at: completed_at,
      duration: duration,
      trigger_object_type: trigger_object_type,
      trigger_object_id: trigger_object_id,
      trigger_user: trigger_user&.name
    }
  end

  private

  def check_approval_completion
    current_step_obj = current_step_object
    return unless current_step_obj&.step_type == 'approval'
    
    approvals = approval_requests.where(workflow_step: current_step_obj)
    
    if approvals.all? { |a| a.approved? }
      current_step_obj.update!(status: 'completed')
      advance_to_next_step!
    elsif approvals.any? { |a| a.rejected? }
      workflow.cancel_workflow(self, 'Approval rejected')
    end
  end
end