# frozen_string_literal: true

# == Schema Information
#
# Table name: approval_requests
#
#  id                  :uuid             not null, primary key
#  workflow_instance_id :uuid            not null
#  workflow_step_id    :uuid             not null
#  approver_id         :uuid             not null
#  status              :string(255)      default('pending'), not null
#  due_date            :datetime
#  comments            :text
#  approved_at         :datetime
#  rejected_at         :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_approval_requests_on_workflow_instance_id  (workflow_instance_id)
#  index_approval_requests_on_workflow_step_id      (workflow_step_id)
#  index_approval_requests_on_approver_id           (approver_id)
#  index_approval_requests_on_status                (status)
#

class ApprovalRequest < ApplicationRecord
  belongs_to :workflow_instance
  belongs_to :workflow_step
  belongs_to :approver, class_name: 'User'

  validates :status, inclusion: { in: %w[pending approved rejected] }

  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :overdue, -> { where(status: 'pending').where('due_date < ?', Time.current) }

  def approved?
    status == 'approved'
  end

  def rejected?
    status == 'rejected'
  end

  def pending?
    status == 'pending'
  end

  def overdue?
    pending? && due_date.present? && due_date < Time.current
  end

  def days_until_due
    return nil unless due_date.present?
    
    (due_date - Time.current) / 1.day
  end

  def days_overdue
    return 0 unless overdue?
    
    (Time.current - due_date) / 1.day
  end

  def status_display
    return 'Overdue' if overdue?
    return 'Approved' if approved?
    return 'Rejected' if rejected?
    'Pending'
  end

  def urgency_level
    return 'critical' if overdue?
    return 'high' if days_until_due.present? && days_until_due < 1
    return 'medium' if days_until_due.present? && days_until_due < 3
    'low'
  end
end