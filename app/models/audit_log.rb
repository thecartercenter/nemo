# frozen_string_literal: true

# == Schema Information
#
# Table name: audit_logs
#
#  id         :uuid             not null, primary key
#  action     :string(255)      not null
#  resource   :string(255)      not null
#  resource_id :uuid
#  changes    :jsonb
#  metadata   :jsonb
#  ip_address :string(255)
#  user_agent :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#  mission_id :uuid
#
# Indexes
#
#  index_audit_logs_on_mission_id    (mission_id)
#  index_audit_logs_on_resource      (resource)
#  index_audit_logs_on_resource_id   (resource_id)
#  index_audit_logs_on_user_id       (user_id)
#  index_audit_logs_on_action        (action)
#  index_audit_logs_on_created_at    (created_at)
#
# Foreign Keys
#
#  audit_logs_mission_id_fkey  (mission_id => missions.id) ON DELETE => cascade
#  audit_logs_user_id_fkey     (user_id => users.id) ON DELETE => cascade
#

class AuditLog < ApplicationRecord
  include MissionBased

  belongs_to :user
  belongs_to :mission, optional: true

  validates :action, presence: true
  validates :resource, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_resource, ->(resource) { where(resource: resource) }
  scope :by_user, ->(user) { where(user: user) }
  scope :in_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  ACTIONS = %w[
    create
    update
    destroy
    login
    logout
    export
    import
    view
    download
    print
    publish
    unpublish
    review
    approve
    reject
    assign
    unassign
    activate
    deactivate
  ].freeze

  RESOURCES = %w[
    User
    Form
    Response
    Question
    OptionSet
    Report
    Mission
    Assignment
    Broadcast
    Setting
    Notification
  ].freeze

  validates :action, inclusion: { in: ACTIONS }
  validates :resource, inclusion: { in: RESOURCES }

  def self.log_action(user, action, resource, resource_id: nil, changes: nil, metadata: nil, request: nil)
    create!(
      user: user,
      action: action.to_s,
      resource: resource.to_s,
      resource_id: resource_id,
      changes: changes,
      metadata: metadata,
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent,
      mission: user.current_mission
    )
  end

  def self.log_login(user, request)
    log_action(user, :login, :User, resource_id: user.id, request: request)
  end

  def self.log_logout(user, request)
    log_action(user, :logout, :User, resource_id: user.id, request: request)
  end

  def self.log_export(user, export_type, format, request)
    log_action(
      user, 
      :export, 
      :Data, 
      metadata: { export_type: export_type, format: format },
      request: request
    )
  end

  def self.log_data_access(user, resource, resource_id, action, request)
    log_action(
      user,
      action,
      resource,
      resource_id: resource_id,
      request: request
    )
  end

  def self.log_system_event(event, details = {})
    # For system events, we might not have a user
    create!(
      action: event.to_s,
      resource: :System,
      metadata: details,
      mission: nil
    )
  end

  def formatted_changes
    return nil unless changes.present?
    
    changes.map do |field, change|
      if change.is_a?(Array) && change.length == 2
        "Changed #{field} from '#{change[0]}' to '#{change[1]}'"
      else
        "Updated #{field}: #{change}"
      end
    end.join(', ')
  end

  def human_readable_action
    case action
    when 'create'
      'Created'
    when 'update'
      'Updated'
    when 'destroy'
      'Deleted'
    when 'login'
      'Logged in'
    when 'logout'
      'Logged out'
    when 'export'
      'Exported'
    when 'import'
      'Imported'
    when 'view'
      'Viewed'
    when 'download'
      'Downloaded'
    when 'print'
      'Printed'
    when 'publish'
      'Published'
    when 'unpublish'
      'Unpublished'
    when 'review'
      'Reviewed'
    when 'approve'
      'Approved'
    when 'reject'
      'Rejected'
    when 'assign'
      'Assigned'
    when 'unassign'
      'Unassigned'
    when 'activate'
      'Activated'
    when 'deactivate'
      'Deactivated'
    else
      action.humanize
    end
  end

  def resource_name
    return 'System' if resource == 'System'
    return 'Unknown' unless resource_id.present?
    
    begin
      resource_class = resource.constantize
      resource_object = resource_class.find(resource_id)
      
      case resource
      when 'User'
        resource_object.name
      when 'Form'
        resource_object.name
      when 'Response'
        "Response #{resource_object.shortcode}"
      when 'Question'
        resource_object.name
      when 'OptionSet'
        resource_object.name
      when 'Report'
        resource_object.name
      when 'Mission'
        resource_object.name
      else
        "#{resource} ##{resource_id}"
      end
    rescue ActiveRecord::RecordNotFound
      "#{resource} ##{resource_id} (deleted)"
    end
  end
end