# frozen_string_literal: true

module AuditLogging
  extend ActiveSupport::Concern

  included do
    around_action :set_current_user_for_audit
  end

  private

  def set_current_user_for_audit
    Thread.current[:current_user] = current_user
    yield
  ensure
    Thread.current[:current_user] = nil
  end

  def log_audit_action(action, resource, resource_id: nil, changes: nil, metadata: nil)
    AuditLog.log_action(
      current_user,
      action,
      resource,
      resource_id: resource_id,
      changes: changes,
      metadata: metadata,
      request: request
    )
  end

  def log_data_access(resource, resource_id, action)
    AuditLog.log_data_access(
      current_user,
      resource,
      resource_id,
      action,
      request
    )
  end

  def log_export(export_type, format)
    AuditLog.log_export(
      current_user,
      export_type,
      format,
      request
    )
  end
end