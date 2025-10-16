# frozen_string_literal: true

# == Schema Information
#
# Table name: workflows
#
#  id          :uuid             not null, primary key
#  name        :string(255)      not null
#  description :text
#  workflow_type :string(255)    not null
#  config      :jsonb
#  active      :boolean          default(TRUE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  mission_id  :uuid
#  user_id     :uuid
#
# Indexes
#
#  index_workflows_on_mission_id     (mission_id)
#  index_workflows_on_user_id        (user_id)
#  index_workflows_on_workflow_type  (workflow_type)
#

class Workflow < ApplicationRecord
  include MissionBased

  belongs_to :user
  belongs_to :mission
  has_many :workflow_instances, dependent: :destroy
  has_many :workflow_steps, dependent: :destroy

  validates :name, presence: true, length: { maximum: 255 }
  validates :workflow_type, presence: true, inclusion: { in: WORKFLOW_TYPES }
  validates :config, presence: true

  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(workflow_type: type) }

  WORKFLOW_TYPES = %w[
    response_approval
    form_review
    data_validation
    user_onboarding
    mission_setup
    report_generation
    data_export
    notification_workflow
  ].freeze

  def create_instance(trigger_object, trigger_user = nil)
    instance = workflow_instances.create!(
      trigger_object: trigger_object,
      trigger_user: trigger_user || user,
      status: 'pending',
      current_step: 0
    )

    # Initialize the first step
    initialize_first_step(instance)
    
    instance
  end

  def next_step(instance)
    return nil if instance.completed?

    current_step = instance.workflow_steps.find_by(step_number: instance.current_step)
    return nil unless current_step

    # Process current step
    process_step(instance, current_step)

    # Move to next step
    next_step_number = instance.current_step + 1
    next_step = workflow_steps.find_by(step_number: next_step_number)

    if next_step
      instance.update!(current_step: next_step_number)
      initialize_step(instance, next_step)
    else
      complete_workflow(instance)
    end

    instance
  end

  def complete_workflow(instance)
    instance.update!(
      status: 'completed',
      completed_at: Time.current
    )

    # Trigger completion actions
    trigger_completion_actions(instance)
  end

  def cancel_workflow(instance, reason = nil)
    instance.update!(
      status: 'cancelled',
      cancelled_at: Time.current,
      cancellation_reason: reason
    )
  end

  private

  def initialize_first_step(instance)
    first_step = workflow_steps.order(:step_number).first
    return unless first_step

    initialize_step(instance, first_step)
  end

  def initialize_step(instance, step)
    case step.step_type
    when 'approval'
      initialize_approval_step(instance, step)
    when 'notification'
      initialize_notification_step(instance, step)
    when 'validation'
      initialize_validation_step(instance, step)
    when 'action'
      initialize_action_step(instance, step)
    end
  end

  def process_step(instance, step)
    case step.step_type
    when 'approval'
      process_approval_step(instance, step)
    when 'notification'
      process_notification_step(instance, step)
    when 'validation'
      process_validation_step(instance, step)
    when 'action'
      process_action_step(instance, step)
    end
  end

  def initialize_approval_step(instance, step)
    # Create approval request
    approvers = determine_approvers(step)
    
    approvers.each do |approver|
      ApprovalRequest.create!(
        workflow_instance: instance,
        workflow_step: step,
        approver: approver,
        status: 'pending',
        due_date: step.config['due_date']&.to_time || 7.days.from_now
      )
    end
  end

  def process_approval_step(instance, step)
    # Check if all approvals are received
    approvals = instance.approval_requests.where(workflow_step: step)
    
    if approvals.all? { |a| a.approved? }
      step.update!(status: 'completed')
    elsif approvals.any? { |a| a.rejected? }
      step.update!(status: 'rejected')
      instance.update!(status: 'rejected')
    end
  end

  def initialize_notification_step(instance, step)
    # Send notifications
    recipients = determine_notification_recipients(step)
    
    recipients.each do |recipient|
      Notification.create_for_user(
        recipient,
        'workflow_notification',
        step.config['title'] || "Workflow Notification",
        message: step.config['message'] || "You have a workflow notification",
        data: {
          workflow_id: id,
          workflow_instance_id: instance.id,
          step_id: step.id
        },
        mission: mission
      )
    end

    step.update!(status: 'completed')
  end

  def process_notification_step(instance, step)
    # Notifications are typically completed immediately
    step.update!(status: 'completed')
  end

  def initialize_validation_step(instance, step)
    # Run validation
    validation_result = run_validation(instance, step)
    
    if validation_result[:passed]
      step.update!(status: 'completed')
    else
      step.update!(status: 'failed')
      instance.update!(status: 'failed')
    end
  end

  def process_validation_step(instance, step)
    # Validations are typically completed immediately
    # This method is here for consistency
  end

  def initialize_action_step(instance, step)
    # Execute action
    action_result = execute_action(instance, step)
    
    if action_result[:success]
      step.update!(status: 'completed')
    else
      step.update!(status: 'failed')
      instance.update!(status: 'failed')
    end
  end

  def process_action_step(instance, step)
    # Actions are typically completed immediately
    # This method is here for consistency
  end

  def determine_approvers(step)
    approver_config = step.config['approvers'] || {}
    
    case approver_config['type']
    when 'role'
      mission.users.joins(:assignments)
             .where(assignments: { role: approver_config['roles'] })
    when 'user'
      User.where(id: approver_config['user_ids'])
    when 'group'
      UserGroup.find(approver_config['group_id']).users
    else
      [user] # Default to workflow creator
    end
  end

  def determine_notification_recipients(step)
    notification_config = step.config['recipients'] || {}
    
    case notification_config['type']
    when 'role'
      mission.users.joins(:assignments)
             .where(assignments: { role: notification_config['roles'] })
    when 'user'
      User.where(id: notification_config['user_ids'])
    when 'group'
      UserGroup.find(notification_config['group_id']).users
    else
      [user] # Default to workflow creator
    end
  end

  def run_validation(instance, step)
    validation_type = step.config['validation_type']
    
    case validation_type
    when 'ai_validation'
      AiValidationService.validate_response(instance.trigger_object)
    when 'custom_validation'
      # Execute custom validation logic
      { passed: true, message: 'Custom validation passed' }
    else
      { passed: true, message: 'No validation specified' }
    end
  end

  def execute_action(instance, step)
    action_type = step.config['action_type']
    
    case action_type
    when 'send_email'
      send_email_action(instance, step)
    when 'update_status'
      update_status_action(instance, step)
    when 'create_notification'
      create_notification_action(instance, step)
    else
      { success: true, message: 'Action completed' }
    end
  end

  def send_email_action(instance, step)
    # Implementation for sending emails
    { success: true, message: 'Email sent' }
  end

  def update_status_action(instance, step)
    object = instance.trigger_object
    status_field = step.config['status_field'] || 'status'
    new_status = step.config['new_status']
    
    if object.respond_to?("#{status_field}=")
      object.update!(status_field => new_status)
      { success: true, message: "Status updated to #{new_status}" }
    else
      { success: false, message: 'Status field not found' }
    end
  end

  def create_notification_action(instance, step)
    # Implementation for creating notifications
    { success: true, message: 'Notification created' }
  end

  def trigger_completion_actions(instance)
    completion_actions = config['completion_actions'] || []
    
    completion_actions.each do |action|
      case action['type']
      when 'webhook'
        trigger_webhook(action, instance)
      when 'notification'
        send_completion_notification(action, instance)
      when 'update_object'
        update_trigger_object(action, instance)
      end
    end
  end

  def trigger_webhook(action, instance)
    webhook_url = action['url']
    payload = build_webhook_payload(instance)
    
    # Send webhook (simplified implementation)
    # In a real implementation, you'd use a proper HTTP client
    Rails.logger.info "Webhook triggered: #{webhook_url} with payload: #{payload}"
  end

  def send_completion_notification(action, instance)
    recipients = determine_notification_recipients_for_action(action)
    
    recipients.each do |recipient|
      Notification.create_for_user(
        recipient,
        'workflow_completed',
        action['title'] || "Workflow Completed",
        message: action['message'] || "Workflow '#{name}' has been completed",
        data: {
          workflow_id: id,
          workflow_instance_id: instance.id
        },
        mission: mission
      )
    end
  end

  def update_trigger_object(action, instance)
    object = instance.trigger_object
    updates = action['updates'] || {}
    
    object.update!(updates)
  end

  def build_webhook_payload(instance)
    {
      workflow_id: id,
      workflow_name: name,
      instance_id: instance.id,
      status: instance.status,
      trigger_object_type: instance.trigger_object_type,
      trigger_object_id: instance.trigger_object_id,
      completed_at: instance.completed_at
    }
  end

  def determine_notification_recipients_for_action(action)
    # Similar to determine_notification_recipients but for completion actions
    [user]
  end
end